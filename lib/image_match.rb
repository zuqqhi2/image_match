require "opencv"
include OpenCV

require "image_match/version"

module ImageMatch
  #====================================================================
  # Private functions
  #====================================================================
  
  def compare_surf_descriptors(d1, d2, best, length)
    raise ArgumentError unless (length % 4) == 0
    total_cost = 0
    0.step(length - 1, 4) { |i|
      t0 = d1[i] - d2[i]
      t1 = d1[i + 1] - d2[i + 1]
      t2 = d1[i + 2] - d2[i + 2]
      t3 = d1[i + 3] - d2[i + 3]
      total_cost += t0 * t0 + t1 * t1 + t2 * t2 + t3 * t3
      break if total_cost > best
    }
    total_cost
  end
  
  def naive_nearest_neighbor(vec, laplacian, model_keypoints, model_descriptors)
    length = model_descriptors[0].size
    neighbor = nil
    dist1 = 1e6
    dist2 = 1e6
  
    model_descriptors.size.times { |i|
      kp = model_keypoints[i]
      mvec = model_descriptors[i]
      next if laplacian != kp.laplacian
      
      d = compare_surf_descriptors(vec, mvec, dist2, length)
      if d < dist1
        dist2 = dist1
        dist1 = d
        neighbor = i
      elsif d < dist2
        dist2 = d
      end
    }
  
    return (dist1 < 0.6 * dist2) ? neighbor : nil
  end
  
  def find_pairs(template_keypoints, template_descriptors, scene_keypoints, scene_descriptors)
    ptpairs = []
    template_descriptors.size.times { |i|
      kp = template_keypoints[i]
      descriptor = template_descriptors[i]
      nearest_neighbor = naive_nearest_neighbor(descriptor, kp.laplacian, scene_keypoints, scene_descriptors)
      unless nearest_neighbor.nil?
        ptpairs << i
        ptpairs << nearest_neighbor
      end
    }
    ptpairs
  end
  
  def locate_planar_template(template_keypoints, template_descriptors, scene_keypoints, scene_descriptors, src_corners)
    ptpairs = find_pairs(template_keypoints, template_descriptors, scene_keypoints, scene_descriptors)
    n = ptpairs.size / 2
    
    return nil if n < 4
  
    pt1 = []
    pt2 = []
    n.times { |i|
      pt1 << template_keypoints[ptpairs[i * 2]].pt
      pt2 << scene_keypoints[ptpairs[i * 2 + 1]].pt
    }
  
    _pt1 = CvMat.new(1, n, CV_32F, 2)
    _pt2 = CvMat.new(1, n, CV_32F, 2)
    _pt1.set_data(pt1)
    _pt2.set_data(pt2)
    h = CvMat.find_homography(_pt1, _pt2, :ransac, 5)
  
    dst_corners = []
    4.times { |i|
      x = src_corners[i].x
      y = src_corners[i].y
      z = 1.0 / (h[6][0] * x + h[7][0] * y + h[8][0])
      x = (h[0][0] * x + h[1][0] * y + h[2][0]) * z
      y = (h[3][0] * x + h[4][0] * y + h[5][0]) * z
      dst_corners << CvPoint.new(x.to_i, y.to_i)
    }
  
    dst_corners
  end


  def get_object_location(scene_filename, template_filename)
    scene, template = nil, nil
    begin  
      scene    = IplImage.load(scene_filename, CV_LOAD_IMAGE_GRAYSCALE)
      template = IplImage.load(template_filename, CV_LOAD_IMAGE_GRAYSCALE)
    rescue
      raise RuntimeError, 'Couldn\'t read image files correctly'
      return false
    end
  
    return nil unless scene.width >= template.width and scene.height >= template.height
    
    param = CvSURFParams.new(1500)
    template_keypoints, template_descriptors = template.extract_surf(param)
    scene_keypoints, scene_descriptors       = scene.extract_surf(param)
    
    src_corners = [CvPoint.new(0, 0), 
                   CvPoint.new(template.width, 0),
                   CvPoint.new(template.width, template.height),
                   CvPoint.new(0, template.height)]
    return locate_planar_template(template_keypoints, 
                                  template_descriptors,
                                  scene_keypoints,
                                  scene_descriptors,
                                  src_corners)
  end

  
  #====================================================================
  # Public Interface
  #====================================================================
  
  ##
  #
  # Calculate matching score of 1st input image and 2nd input image
  # required the sizes are same.
  #
  # @param [String] image1_filename    Compare target image1 file path 
  # @param [String] image2_filename    Compare target image2 file path 
  # @param [Float] limit_similarity    Accepting similarity (default is 90% matching)
  # @return [Boolean]                  true  if matching score is higher than limit_similarity
  #                                    false otherwise
  #
  def perfect_match(image1_filename, image2_filename, limit_similarity=0.9)
    raise ArgumentError, 'File does not exists.' unless File.exist?(image1_filename) and File.exist?(image2_filename)
    raise ArgumentError, 'limit_similarity must be 0.1 - 1.0.' unless limit_similarity >= 0.1 and limit_similarity <= 1.0
  
    image1, image2 = nil, nil
    begin
      image1 = IplImage.load(image1_filename)
      image2 = IplImage.load(image2_filename)
    rescue
      raise RuntimeError, 'Couldn\'t read image files correctly'
      return false
    end
  
    return false unless image1.width == image2.width and image1.height == image2.height
  
    return perfect_match_template(image1_filename, image2_filename, limit_similarity)
  end
  
  ##
  #
  # Calculate matching score of 1st input image and 2nd input image.
  # The 2nd input image size must be smaller than 1st input image.
  # This function is robust for brightness.
  #
  # @param [String] scene_filename     Scene image file path
  # @param [String] template_filename  template image file path which you want find in scene image
  # @param [Float] limit_similarity    Accepting similarity (default is 90% matching)
  # @param [Boolean] is_output         if you set true, you can get match result with image (default is false)
  # @return [Boolean]                  true  if matching score is higher than limit_similarity
  #                                    false otherwise
  #
  def perfect_match_template(scene_filename, template_filename, limit_similarity=0.9, is_output=false)
    raise ArgumentError, 'File does not exists.' unless File.exist?(scene_filename) and File.exist?(template_filename)
    raise ArgumentError, 'limit_similarity must be 0.1 - 1.0.' unless limit_similarity >= 0.1 and limit_similarity <= 1.0
    raise ArgumentError, 'is_output must be true or false.' unless is_output == false or is_output == true
    
    scene, template = nil, nil
    begin
      scene    = IplImage.load(scene_filename)
      template = IplImage.load(template_filename)
    rescue
      raise RuntimeError, 'Couldn\'t read image files correctly'
      return false
    end
  
    return false unless scene.width >= template.width and scene.height >= template.height
  
    result   = scene.match_template(template, :ccoeff_normed)
    min_score, max_score, min_point, max_point = result.min_max_loc
  
    if is_output
      from = max_point
      to = CvPoint.new(from.x + template.width, from.y + template.height)
      scene.rectangle!(from, to, :color => CvColor::Red, :thickness => 3)
      scene.save_image(Time.now.to_i.to_s + "_match_result.png")
    end
  
    return (max_score >= limit_similarity ? true : false)
  end
  
  ##
  #
  # Try to find 2nd input image in 1st input image.
  # This function ignores color, size and shape details.
  # (I mean this func checks whether almost same or clearly different)
  #
  # Note that this function is useful I think,
  # but sometimes it doesn't output correct result which you want.
  # It depends on input images.
  # TODO : improve accuracy
  #
  # @param [String] scene_filename     Scene image file path
  # @param [String] template_filename  template image file path which you want find in scene image
  # @param [Boolean] is_output         if you set true, you can get match result with image (default is false)
  # @return [Boolean]                  true  if 1st input image seems to have 2nd input image
  #                                    false otherwise
  #
  def fuzzy_match_template(scene_filename, template_filename, is_output=false)
    raise ArgumentError, 'File does not exists.' unless File.exist?(scene_filename) and File.exist?(template_filename)
    raise ArgumentError, 'is_output must be true or false.' unless is_output == false or is_output == true
    
    scene, template = nil, nil
    begin  
      scene    = IplImage.load(scene_filename, CV_LOAD_IMAGE_GRAYSCALE)
      template = IplImage.load(template_filename, CV_LOAD_IMAGE_GRAYSCALE)
    rescue
      raise RuntimeError, 'Couldn\'t read image files correctly'
      return false
    end
  
    return false unless scene.width >= template.width and scene.height >= template.height
    
    param = CvSURFParams.new(1500)
    template_keypoints, template_descriptors = template.extract_surf(param)
    scene_keypoints, scene_descriptors       = scene.extract_surf(param)
    
    src_corners = [CvPoint.new(0, 0), 
                   CvPoint.new(template.width, 0),
                   CvPoint.new(template.width, template.height),
                   CvPoint.new(0, template.height)]
    dst_corners = locate_planar_template(template_keypoints, 
                                       template_descriptors,
                                       scene_keypoints,
                                       scene_descriptors,
                                       src_corners)
  
  
    if is_output
      correspond = IplImage.new(scene.width, template.height + scene.height, CV_8U, 1);
      correspond.set_roi(CvRect.new(0, 0, template.width, template.height))
      template.copy(correspond)
      correspond.set_roi(CvRect.new(0, template.height, scene.width, scene.height))
      scene.copy(correspond)
      correspond.reset_roi  
      correspond = correspond.GRAY2BGR
  
      if dst_corners
        4.times { |i|
          r1 = dst_corners[i % 4]
          r2 = dst_corners[(i + 1) % 4]
          correspond.line!(CvPoint.new(r1.x, r1.y + template.height),
                           CvPoint.new(r2.x, r2.y + template.height),
                           :color => CvColor::Red,
                           :thickness => 2, :line_type => :aa)
        }
      end
    
      ptpairs = find_pairs(template_keypoints, template_descriptors, scene_keypoints, scene_descriptors)
    
      0.step(ptpairs.size - 1, 2) { |i|
        r1 = template_keypoints[ptpairs[i]]
        r2 = scene_keypoints[ptpairs[i + 1]]
        correspond.line!(r1.pt, CvPoint.new(r2.pt.x, r2.pt.y + template.height),
                         :color => CvColor::Red, :line_type => :aa)
      }
    
      correspond.save_image(Time.now.to_i.to_s + "_match_result.png")
    end
    
    return (dst_corners ? true : false)
  end
  
  ##
  #
  # Calculate matching score of 1st input image and 2nd input image.
  # The 2nd input image size must be smaller than 1st input image.
  # This function is robust for brightness and size.
  #
  # @param [String] scene_filename     Scene image file path
  # @param [String] template_filename  template image file path which you want find in scene image
  # @param [Float] limit_similarity    Accepting similarity (default is 90% matching)
  # @param [Boolean] is_output         if you set true, you can get match result with image (default is false)
  # @return [Boolean]                  true  if matching score is higher than limit_similarity
  #                                    false otherwise
  #
  def match_template_ignore_size(scene_filename, template_filename, limit_similarity=0.9, is_output=false)
    raise ArgumentError, 'File does not exists.' unless File.exist?(scene_filename) and File.exist?(template_filename)
    raise ArgumentError, 'is_output must be true or false.' unless is_output == false or is_output == true

    dst_corners = get_object_location(scene_filename, template_filename)
    
    scene, template = nil, nil
    begin  
      scene    = IplImage.load(scene_filename)
      template = IplImage.load(template_filename)
    rescue
      raise RuntimeError, 'Couldn\'t read image files correctly'
      return false
    end
  
    return false unless scene.width >= template.width and scene.height >= template.height
    
    if dst_corners
      src_corners = [CvPoint.new(0, 0), 
                     CvPoint.new(template.width, 0),
                     CvPoint.new(template.width, template.height),
                     CvPoint.new(0, template.height)]

      resize_width  = (dst_corners[1].x - dst_corners[0].x) - src_corners[1].x
      resize_height = (dst_corners[3].y - dst_corners[0].y) - src_corners[3].y

      template = template.resize(CvSize.new(template.width + resize_width, template.height + resize_height))
    end

    result   = scene.match_template(template, :ccoeff_normed)
    min_score, max_score, min_point, max_point = result.min_max_loc

    if is_output
      from = max_point
      to = CvPoint.new(from.x + template.width, from.y + template.height)
      scene.rectangle!(from, to, :color => CvColor::Red, :thickness => 3)
      scene.save_image(Time.now.to_i.to_s + "_match_result.png")
    end
  
    return (max_score >= limit_similarity ? true : false)
  end

end
