Alexa Top Sites
===============

This is a set of Ruby scripts for interacting with the Alexa Top Sites API.
The basis for the main `topsites.rb` script was taken from a
[Ruby script from 2011 that hits the API](http://aws.amazon.com/code/Alexa-Top-Sites/408).
To run:

    ruby topsites.rb [-c COUNTRY] [-n NUMBER]

COUNTRY can be a comma-separated list; eg, "us,au,jp"

For more information on Alexa, please refer to the [Developer Guide](http://docs.aws.amazon.com/AlexaTopSites/latest/).

Author
------
Copyright (c) 2013, [Nate Wiger](http://nateware.com). Released under the MIT License.
