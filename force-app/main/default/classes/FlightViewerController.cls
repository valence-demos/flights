/**
 * Apex controller that backs Lightning components interested in Flight data.
 */
public with sharing class FlightViewerController {

	public static final Pattern commercialAirlines = Pattern.compile('[a-zA-Z]{3}(\\d*)');
	public static final Integer activityCutoffInSeconds = 600;

	@AuraEnabled
	public static List<Flight__c> getAirborneFlights() {
		// only get flight data for flights that we've heard updates from since our cutoff
		Long timestamp = System.now().getTime() / 1000 - activityCutoffInSeconds;

		return [SELECT Id, ICAO24__c, Callsign__c, Origin_Country__c, Location__Latitude__s, Location__Longitude__s, Baro_Altitude__c, Velocity__c, Vertical_Rate__c, Squawk__c FROM Flight__c WHERE On_Ground__c = FALSE AND Time_Position__c > :timestamp];
	}

	@AuraEnabled
	public static List<Flight__c> getAirborneCommercialFlights() {

		List<Flight__c> allFlights = getAirborneFlights();

		List<Flight__c> commercialFlights = new List<Flight__c>();
		for(Flight__c flight : allFlights) {
			if(String.isNotBlank(flight.Callsign__c) && commercialAirlines.matcher(flight.Callsign__c.trim()).matches())
				commercialFlights.add(flight);
		}

		return commercialFlights;
	}
}