require 'spec_helper'

describe ImageMatch do
  
  before :all do
    @image_dir = File.expand_path(File.dirname(__FILE__)) + '/images'
  end 

 
  describe 'perfect_match' do
    it 'finds that input images are same' do 
      result = perfect_match(@image_dir + '/lena.jpg', @image_dir + '/lena.jpg')
      expect(result).to eq true
    
      result = perfect_match(@image_dir + '/lena.jpg', @image_dir + '/lena.jpg', 0.95)
      expect(result).to eq true
    end

    it 'finds that input images are not same' do
      # Require similarity is too high with noise image
      result = perfect_match(@image_dir + '/lena.jpg', @image_dir + '/lena-noise.jpg', 0.98)
      expect(result).to eq false

      # Size not match
      result = perfect_match(@image_dir + '/lena.jpg', @image_dir + '/lena-eyes.jpg')
      expect(result).to eq false
      
      # File does not exists
      expect{ perfect_match(@image_dir + '/lena.jpg', @image_dir + '/lena-eyes-2nd.jpg') }.to raise_error
    end
  end

  describe 'perfect_match_template' do
    it 'finds that 2nd input image is a part of 1st input image' do
      # Same image 
      result = perfect_match_template(@image_dir + '/lena.jpg', @image_dir + '/lena.jpg')
      expect(result).to eq true
    
      # Template
      result = perfect_match_template(@image_dir + '/lena.jpg', @image_dir + '/lena-eyes.jpg')
      expect(result).to eq true 

      # Set similarity
      result = perfect_match_template(@image_dir + '/lena.jpg', @image_dir + '/lena-eyes.jpg', 0.95)
      expect(result).to eq true

      # Set is_output
      perfect_match_template(@image_dir + '/lena.jpg', @image_dir + '/lena-eyes.jpg', 0.95, true)
      path = File.expand_path(File.dirname(__FILE__))
      result = `ls #{path}/../*_match_result.png | wc -l`
      expect(result.chomp).to eq "1"
    end

    it 'finds that 1st input image doesn\'t contains 2nd input image' do
      # No correlation images
      result = perfect_match_template(@image_dir + '/lena.jpg', @image_dir + '/box.jpg')
      expect(result).to eq false

      # Require similarity is too high with noise image
      result = perfect_match_template(@image_dir + '/lena.jpg', @image_dir + '/lena-noise.jpg', 0.98)
      expect(result).to eq false

      # Size not match
      result = perfect_match_template(@image_dir + '/lena.jpg', @image_dir + '/box_in_scene.jpg')
      expect(result).to eq false
      
      # File does not exists
      expect{ perfect_match_template(@image_dir + '/lena.jpg', @image_dir + '/lena-eyes-2nd.jpg') }.to raise_error      
    end
  end
  
  describe 'fuzzy_match_template' do
    it 'finds that 2nd input image is a part of 1st input image' do
      # Same
      result = fuzzy_match_template(@image_dir + '/box_in_scene.jpg', @image_dir + '/box_in_scene.jpg')
      expect(result).to eq true
    
      # Template
      result = fuzzy_match_template(@image_dir + '/box_in_scene.jpg', @image_dir + '/box.jpg')
      expect(result).to eq true

      # Set is_output
      result = fuzzy_match_template(@image_dir + '/box_in_scene.jpg', @image_dir + '/box.jpg', true)
      path = File.expand_path(File.dirname(__FILE__))
      result = `ls #{path}/../*_match_result.png | wc -l`
      expect(result.chomp).to eq '2'
    end

    it 'finds that 1st input image doesn\'t contains 2nd input image' do
      # No correlation images
      result = fuzzy_match_template(@image_dir + '/box.jpg', @image_dir + '/lena-eyes.jpg', true)
      expect(result).to eq false

      # Size not match
      result = fuzzy_match_template(@image_dir + '/lena.jpg', @image_dir + '/box_in_scene.jpg')
      expect(result).to eq false
      
      # File does not exists
      expect{ fuzzy_match_template(@image_dir + '/lena.jpg', @image_dir + '/lena-eyes-2nd.jpg') }.to raise_error      
    end
  end
  
  describe 'match_template_ignore_size' do
    it 'finds that 2nd input image is a part of 1st input image' do
      # Same
      result = match_template_ignore_size(@image_dir + '/stuff.jpg', @image_dir + '/stuff.jpg')
      expect(result).to eq true
    
      # Template
      result = match_template_ignore_size(@image_dir + '/stuff.jpg', @image_dir + '/stuff-lighter.jpg')
      expect(result).to eq true
      result = match_template_ignore_size(@image_dir + '/stuff.jpg', @image_dir + '/stuff-lighter-small.jpg')
      expect(result).to eq true

      # Set is_output
      result = match_template_ignore_size(@image_dir + '/stuff.jpg', @image_dir + '/stuff-lighter-small.jpg', 0.9, true)
      path = File.expand_path(File.dirname(__FILE__))
      result = `ls #{path}/../*_match_result.png | wc -l`
      expect(result.chomp).to eq '3'
    end

    it 'finds that 1st input image doesn\'t contains 2nd input image' do
      # No correlation images
      result = match_template_ignore_size(@image_dir + '/box.jpg', @image_dir + '/lena-eyes.jpg', 0.9, true)
      expect(result).to eq false

      # Size not match
      result = match_template_ignore_size(@image_dir + '/lena.jpg', @image_dir + '/box_in_scene.jpg')
      expect(result).to eq false
      
      # File does not exists
      expect{ match_template_ignore_size(@image_dir + '/lena.jpg', @image_dir + '/lena-eyes-2nd.jpg') }.to raise_error      
    end
  end

  after :all do
    # Delete created files
    path = File.expand_path(File.dirname(__FILE__))
    result = `ls #{path}/../*_match_result.png | wc -l`
    if result != '0'
      `rm #{path}/../*_match_result.png`
    end
  end
end
