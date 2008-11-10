require 'yaml'
config = YAML::load(File.read('config.yml'))

require 'net/http'
require 'digest/md5'
require 'uri'

APIKEY = config["lastfm"]["apikey"]
SECRET = config["lastfm"]["secret"]

def call_last_fm(parameters={})
  parameters["api_key"] = APIKEY
  # puts parameters.inspect
  ordered_parameters = parameters.keys.sort
  # puts ordered_parameters
  concatenated_parameters = ordered_parameters.inject(""){|memo, p| memo + p.to_s + parameters[p]}
  # puts concatenated_parameters
  parameters['api_sig'] = Digest::MD5.hexdigest(concatenated_parameters + SECRET)
  
  url_parameters = parameters.map{|k,v| "#{k}=#{v}"}.join('&')
  
  response = Net::HTTP.get_response('ws.audioscrobbler.com', "/2.0/?#{url_parameters}")
  response.body
end

def get_xml_tag(tagname, body)
  r = Regexp.new("<#{tagname}>(.+)<\/#{tagname}>")
  body.match(r)[1]
end

unless username = config["lastfmlogin"]["username"] && key = config["lastfmlogin"]["key"]
  request_token =  get_xml_tag("token", call_last_fm("method" => "auth.gettoken"))
  
  puts "Please visit:"
  puts "http://www.last.fm/api/auth?api_key=#{APIKEY}&token=#{request_token}"
  line = gets
  
  response = call_last_fm("method" => "auth.getsession", "token" => request_token)
  
  key = get_xml_tag('key', response)
  username = get_xml_tag('name', response)
  puts "LASTFM USER KEY: #{key}"
end



# handshake
timestamp = Time.now.utc.to_i.to_s
authentication_token = Digest::MD5.hexdigest(SECRET + timestamp)
querystring = "/?hs=true&p=1.2.1&c=tst&v=1.0&u=#{username}&t=#{timestamp}&a=#{authentication_token}&api_key=#{APIKEY}&sk=#{key}"
response = Net::HTTP.get_response('post.audioscrobbler.com', querystring)
responses = response.body.split("\n")
# puts responses.inspect
@scrobble_session_id = responses[1]
@submission_url = responses[3]
print responses.inspect
# submission
def submit(artist,title)
  response = Net::HTTP.post_form(URI.parse(@submission_url), {
    's' => @scrobble_session_id,
    'a[0]' => artist,
    't[0]' => title,
    'i[0]' => Time.now.utc.to_i.to_s,
    'o[0]' => 'U',
    'r[0]' => '',
    'l[0]' => '',
    'b[0]' => '',
    'n[0]' => '',
    'm[0]' => ''
  })

  puts response.body
end