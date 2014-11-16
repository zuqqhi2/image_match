# ImageMatch

An simple image match library for view test.

* Ruby 1.9.3 and OpenCV 2.4.10 are supported.

## Requirement

* OpenCV <http://opencv.org/>
  * [Download](http://sourceforge.net/projects/opencvlibrary/)
  * [Install guide](http://docs.opencv.org/doc/tutorials/introduction/table_of_content_introduction/table_of_content_introduction.html#table-of-content-introduction)

## Installation of this library

Add this line to your application's Gemfile:

```ruby
gem 'image_match'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install image_match

## Usage

### Flow

Basic flow is following.

1. Get comparison source and  destination image file.
2. Compare them with this library.

### Interfaces

Following 3 functions are prepared.

1. perfect_match
  Calc match score between image1 and image2.
  This function requires same size image as image1 and image2
  This returns true if match score is higher than limit_similarity.
  When you set true to is_output, you can check matching result with image.
  The image will be created at your current directory.
```ruby
perfect_match(image1_filename, image2_filename, limit_similarity=0.9, is_output=false)
```
2. perfect_match_template
  Try to find template image in scene image.
  This function requires that template image's size is smaller than image2.
  This returns true if match score is higher than limit_similarity.
  When you set true to is_output, you can check matching result with image.
  The output image will be created at your current directory.
```ruby
perfect_match_template(scene_filename, template_filename, limit_similarity=0.9, is_output=false)
```
3. fuzzy_match_template
  Try to find template image in scene image.
  This function requires that template image's size is smaller(or equal) than image2.
  This function ignore image size, color and image detail.
  When you set true to is_output, you can check matching result with image.
  The output image will be created at your current directory.
  Note that ome times this is useful, but accuracy is not so high.
```ruby
fuzzy_match_template(scene_filename, template_filename, is_output=false)
```

### Sample Code

A sample to take screen shot on http://google.com/ and compare screen shot and prepared logo image.
You can check all files related this sample on samples directory(currently sample is only one).

#### Gemfile

```
source 'https://rubygems.org'

gem 'capybara'
gem 'poltergeist'
gem 'image_match'
```

#### Main

```
require 'capybara'
require 'capybara/poltergeist'
require 'image_match'
include ImageMatch

# Get current google web page image
url = 'http://google.com/'
Capybara.javascript_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new app, js_errors: false
end
Capybara.default_selector = :xpath

session = Capybara::Session.new(:poltergeist)
session.driver.headers = {'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X)"}
session.visit(url)

session.save_screenshot('screenshot.png', full: true)

# Compare logo (output match result image)
if perfect_match_template('./screenshot.png', './google-logo.jpg', 0.9, true)
  puts "Same!"
else
  puts "Different..."
end

```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/image_match/fork )
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request to develop branch
Note that develop branch is newest version(not release version).

## LICENSE:

The BSD Liscense

see LICENSE.txt
