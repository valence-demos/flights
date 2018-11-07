({
	doInit : function(component, event, helper) {
		let action = component.get('c.getAirborneCommercialFlights');
		action.setCallback(this, function(a) {
			component.set('v.flights', a.getReturnValue());
			component.set('v.flightsLoaded', true);
			helper.applyMarkers(component);
		});
		$A.enqueueAction(action);
	},

	jsLoaded : function(component, event, helper) {
		//center: [42.6679945, -71.840887]
		let map = L.map('map', {zoomControl : false, tap : false});
		map.fitBounds([[41.976433,-73.041723],[43.359556,-70.640051]]);
		L.marker([41.976433, -73.041723]).addTo(map);
		L.marker([41.976433, -70.640051]).addTo(map);
		L.marker([43.359556, -73.041723]).addTo(map);
		L.marker([43.359556, -70.640051]).addTo(map);
		L.tileLayer(
			'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
			{
				attribution : 'Tiles © Esri'
			}).addTo(map);
		component.set('v.mapRef', map);
		component.set('v.mapLoaded', true);
		helper.applyMarkers(component);
	}
});