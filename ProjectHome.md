dependns-iphone-implementation is a web browser embedded application for preventing pharming or phishing while iphone users. The original idea comes from the proposed countermeasure against DNS cache poisoning, called **DepenDNS**. DepenDNS queries multiple resolvers concurrently to verify an trustworthy answer while users perform payment transactions, e.g., auction, banking. Right now, the program provides protection while users surfing on the websites. After users  click **Detect** button, the website would load web content and run detection algorithm for the
current ip address your browser connected. Then you can shake the iphone to get results showing in different colors. Blue text means safe, and red text means it might suffer pharming. If you git orange colors, it means the DNS engine could not gather enough information to analyze. Hence, you should press **Detect** button again.

**Detail about DepenDNS is given in the following link.**
_[DepenDNS](http://www.springerlink.com/content/kg6p652732425008/)_

It currently works on iPhone or iPod Touch platform with iPhone OS version >=3.0. Right now we already submitted this application to the iTunes app store. We wish the application could be available soon.

I haven't been able to fully test everything yet, so report any issues you find at http://code.google.com/p/dependns-iphone-implementation/issues/list

Screenshots are viewable on the Wiki Screenshots page:
http://code.google.com/p/dependns-iphone-implementation/wiki/Screenshot

Please give us your valuable suggestions!

Version History is available here:
http://code.google.com/p/dependns-iphone-implementation/source/list
