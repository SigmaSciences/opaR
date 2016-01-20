opaR
=====

opaR (object pascal for R) is a port of [R.NET 1.6.5](https://github.com/jmp75/rdotnet) to Embarcadero Delphi, allowing you to integrate the popular R statistical language into your Delphi apps.  

Delphi is a natural fit for this - no opaque marshalling and no runtime requirement (as well as being cross-platform). The direct pointer access combined with the .NET-style features available in more recent Delphi versions made the port relatively straightforward. The aim has been to retain the same basic API as in R.NET, allowing simple porting of the numerous R.NET examples found on the web.


Requirements
--------------

1. [The Spring4D Collections](https://bitbucket.org/sglienke/spring4d) 

2. [Generics.Tuples from Malcolm Groves](https://github.com/malcolmgroves/generics.tuples)


Notes
-------
As of Jan 2016:

1. This is still beta software - use at your own risk! 

2. Currently only the non-visual core has been ported. There are no definite plans to port the graphics classes, but it's a possibility.

3. Developed in XE7 on Win7 32bit, with x64 testing in Delphi 10 Seattle (on Win8 64bit). Because of it's origins, opaR uses the .NET-style features found in more recent Delphi versions and there are no plans to validate against earlier versions, or against FPC. 

4. Developed using R 3.2.2 (both 32 and 64 bit on Windows). Not tested with earlier R versions and there are no plans to do so.

5. Most of the integration tests provided with R.NET 1.6.5 have been ported, and additional tests from other sources will be added over time. However, there's some way to go before full code coverage is achieved. Testing is based on the DUnit version provided with the IDE.

6. Testing on OSX will be started in the near future (and Linux when it becomes available).

7. GPL code (and hence R) is not allowed in the Apple AppStore so an iOS port is unlikely, although we'll take a look at Android at some point.

8. There are still a few gaps (e.g. handling of complex types, and some Linux-related code) and these will be added in the near future.


Licence
--------

R itself is released under the GPL and for consistency opaR is similarly licenced (actually Affero GPL). Be aware that if you incorporate opaR into one of your products then you are also, by default, incorporating R and your codebase becomes subject to GPL conditions. Releasing opaR under a licence such as Mozilla (MPL) or Apache won't allow you to avoid the GPL conditions dragged in by R itself, and confuses the situation. opaR is likely to be most useful for software developed for internal corporate use, where there is no requirement to release source code under GPL.


Acknowledgements
-------------------

This port has been made straightforward by the excellent resources found in the Delphi community, in particular those due to Stefan Glienke, David Heffernan, Rudi Velthuis, Nick Hodges and Remy Lebeau.

