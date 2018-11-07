({
	/**
	 * Attempt to attach flight markers to the map.
	 */
	applyMarkers : function(component) {

		// if our flags aren't set, bail out
		if(!component.get('v.mapLoaded') || !component.get('v.flightsLoaded'))
			return;

		// custom icon class for our airplane markers
		let AirplaneIcon = L.Icon.extend({
			options: {
				iconUrl: '/resource/airplane/airplane_stroke.svg',
				iconSize: [64,64]
			}
		});

		let map = component.get('v.mapRef'), flights = component.get('v.flights');
		flights.forEach(function(flight){
			L.marker([flight.Location__Latitude__s, flight.Location__Longitude__s],{
				title: flight.Callsign__c,
				icon: new AirplaneIcon()
			}).addTo(map);
		});
	}
});