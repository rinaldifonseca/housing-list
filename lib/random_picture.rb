require 'json'
require 'open-uri'
require 'uri'

class RandomPicture
  MIN_WIDTH  = 2800
  MIN_HEIGHT = 1000

  MIME_TYPES = %w(image/png image/jpeg)

  private
  attr_reader :destination, :license

  public
  def self.find(destination)
    new(destination).find
  end

  def initialize(destination)
    @destination = destination
    @license     = 'CC-SA-1.0'
  end

  def find
    response = call_api
    image    = pick_best_image(response)

    return image['url']
  end

  private

  def api_url
    base_url = 'https://commons.wikimedia.org/w/api.php'
    params   = {
      format:    'json',
      action:    'query',
      titles:    destination,
      list:      'categorymembers',
      cmtype:    'file',
      cmtitle:   "Category:#{license}",
      generator: 'images',
      prop:      'imageinfo',
      iiprop:    'url|size|dimensions|mime',
      gimlimit:  '5',
      redirects: '1'
    }

    encoded_params = URI.encode_www_form(params)

    return "#{base_url}?#{encoded_params}"
  end

  def call_api
    response = open(api_url).read
    return JSON.parse(response)
  end

  def pick_best_image(response)
    images = response['query'].fetch('pages', {}).values

    image = images.find do |image|
      image_details = image['imageinfo'].first
      width         = image_details['width']
      height        = image_details['height']
      mime_type     = image_details['mime']

      # RULES:
      # - acceptable mime type
      # - min width and min height respected
      MIME_TYPES.include?(mime_type) && (width >= MIN_WIDTH && height >= MIN_HEIGHT)
    end

    return {} unless image
    image['imageinfo'].first
  end
end
