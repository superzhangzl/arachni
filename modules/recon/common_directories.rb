=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

require 'digest/sha1'

module Arachni

module Modules

#
# Common directories discovery module.
#
# Looks for common, possibly sensitive, directories on the server.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1.4
#
# @see http://cwe.mitre.org/data/definitions/538.html
#
#
class CommonDirectories < Arachni::Module::Base

    include Arachni::Module::Utilities

    def initialize( page )
        super( page )

        @__common_directories = 'directories.txt'

        # to keep track of the requests and not repeat them
        @@__audited ||= []
        @results   = []
    end

    def run( )

        print_status( "Scanning..." )

        path = get_path( @page.url )

        read_file( @__common_directories ) {
            |dirname|

            url  = path + dirname + '/'

            next if @@__audited.include?( url )
            print_status( "Checking for #{url}" )

            req  = @http.get( url, :train => true )
            @@__audited << url

            req.on_complete {
                |res|
                print_status( "Analyzing #{res.effective_url}" )
                __log_results( res, dirname )
            }
        }

    end

    def self.info
        {
            :name           => 'CommonDirectories',
            :description    => %q{Tries to find common directories on the server.},
            :elements       => [ ],
            :author         => 'zapotek',
            :version        => '0.1.4',
            :references     => {},
            :targets        => { 'Generic' => 'all' },
            :vulnerability   => {
                :name        => %q{A common directory exists on the server.},
                :description => %q{},
                :cwe         => '538',
                :severity    => Vulnerability::Severity::MEDIUM,
                :cvssv2       => '',
                :remedy_guidance    => '',
                :remedy_code => '',
            }

        }
    end

    #
    # Adds a vulnerability to the @results array<br/>
    # and outputs an "OK" message with the dirname and its url.
    #
    # @param  [Net::HTTPResponse]  res   the HTTP response
    # @param  [String]  dirname   the discovered dirname
    # @param  [String]  url   the url of the discovered file
    #
    def __log_results( res, dirname )

        return if( res.code != 200 || @http.custom_404?( res ) )

        url = res.effective_url
        # append the result to the results array
        @results << Vulnerability.new( {
            :var          => 'n/a',
            :url          => url,
            :injected     => dirname,
            :id           => dirname,
            :regexp       => 'n/a',
            :regexp_match => 'n/a',
            :elem         => Vulnerability::Element::PATH,
            :response     => res.body,
            :headers      => {
                :request    => res.request.headers,
                :response   => res.headers,
            }
        }.merge( self.class.info ) )

        # inform the user that we have a match
        print_ok( "Found #{dirname} at " + url )

        # register our results with the system
        register_results( @results )

    end

end
end
end
