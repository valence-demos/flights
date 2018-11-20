# Valence Flights Demo #

This demo was used to win the Northeast Dreamin 2018 Demo Jam.

It mashes up the [Open Sky Network API](https://opensky-network.org/) with the [Geolocation Trailhead Project](https://trailhead.salesforce.com/en/content/learn/projects/account-geolocation-app) to build a real-time Flight viewer.

![Live flights in the air above the conference location](/images/demo.jpg)

## Building the DX Project ##

By default this repo is set up as DX project for you to run the demo in a scratch org. Clone this repo to your local machine and then execute the following build script from the repository root folder:

`./build`

## Project Composition ##

Data movement is handled with [Valence](http://valencedata.com) by the use of a custom Adapter that knows how fetch data from the Open Sky API. You can find the code for this in the Apex class `OpenSkyAdapter`.

Flight data is written to a custom object called `Flight__c`.

A custom Lightning Component `FlightViewer` is displayed on a tab called "Flight Viewer", and renders a map using the [Leaflet](https://leafletjs.com) javascript mapping library. An Apex class `FlightViewerController` delivers `Flight__c` records to the Lightning component. 