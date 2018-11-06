/**
 * Open-source Valence Adapter (http://valencedata.com) designed to talk to the OpenSky Network API (https://opensky-network.org/).
 *
 * @see http://docs.valencedata.com
 * @see https://opensky-network.org/apidoc/
 */
global with sharing class OpenSkyAdapter implements valence.NamedCredentialAdapter, valence.SchemaAdapter, valence.ConfigurableSourceAdapter, valence.SourceAdapterForPull {

	private String namedCredentialName = null;

	private Configuration config = null;

	// --------------------------------------------
	// ---- NamedCredentialAdapter methods --------
	// --------------------------------------------

	public void setNamedCredential(String namedCredentialName) {
		this.namedCredentialName = namedCredentialName;
	}

	// --------------------------------------------
	// ---- SchemaAdapter methods -----------------
	// --------------------------------------------

	public List<valence.Table> getTables() {

		List<valence.Table> tables = new List<valence.Table>();
		for(OpenSkyEndpoint endpoint : apiEndpoints)
			tables.add(valence.Table.create(endpoint.name).withLabel(endpoint.label).setEditable(false).build());
		return tables;
	}

	public List<valence.Field> getFields(String tableApiName) {

		return getEndpoint(tableApiName).getFields();
	}

	// --------------------------------------------
	// ---- ConfigurableSourceAdapter methods -----
	// --------------------------------------------

	public String getSourceConfigurationLightningComponent(valence.LinkContext context) {
		return null;
	}

	public String getSourceConfigurationStructure(valence.LinkContext context) {
		return getEndpoint(context.linkSourceName).getConfigurationStructure();
	}

	public String explainSourceConfiguration(valence.LinkContext context, String configurationData) {
		try {
			config = (OpenSkyAdapter.Configuration)JSON.deserialize(configurationData, OpenSkyAdapter.Configuration.class);
			return getEndpoint(context.linkSourceName).explainConfiguration(config);
		}
		catch(Exception e) {
			return '<span class="slds-text-color_error">The current configuration is malformed and needs to be fixed before this Link will work.</span>';
		}
	}

	public void setSourceConfiguration(valence.LinkContext context, String configurationData) {

		try {
			config = (OpenSkyAdapter.Configuration)JSON.deserialize(configurationData, OpenSkyAdapter.Configuration.class);
		}
		catch(Exception e) {
			throw new valence.AdapterException('Cannot parse the source adapter configuration: ' + configurationData);
		}
	}

	// --------------------------------------------
	// ---- SourceAdapterForPull methods ----------
	// --------------------------------------------

	public valence.FetchStrategy planFetch(valence.LinkContext context) {

		return valence.FetchStrategy.immediate();
	}

	public List<valence.RecordInFlight> fetchRecords(valence.LinkContext context, Object scope) {

		return getEndpoint(context.linkSourceName).parseRecords(queryAPI(context));
	}

	// --------------------------------------------
	// ---- Helper methods ------------------------
	// --------------------------------------------

	private OpenSkyEndpoint getEndpoint(String name) {
		OpenSkyEndpoint endpoint = null;
		for(OpenSkyEndpoint apiEndpoint : apiEndpoints) {
			if(apiEndpoint.name.equalsIgnoreCase(name))
				endpoint = apiEndpoint;
		}
		return endpoint;
	}

	private valence.JSONParse queryAPI(valence.LinkContext context) {

		OpenSkyEndpoint endpoint = getEndpoint(context.linkSourceName);
		if(endpoint == null)
			throw new valence.AdapterException('Unknown OpenSky API Endpoint');

		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
		req.setTimeout(120000);
		req.setEndpoint('callout:' + namedCredentialName + endpoint.buildURL(context, config));

		System.debug(LoggingLevel.WARN, req.getEndpoint());

		HttpResponse res = new Http().send(req);

		valence.JSONParse response = new valence.JSONParse(res.getBody());

		return response;
	}

	/**
	 * Simple class for holding the configuration needed for this filter.
	 */
	private class Configuration {

		private Boolean bounded; // toggle for whether boundaries should be applied or ignored
		private Decimal lamin; // lower bound for the latitude in decimal degrees
		private Decimal lamax; // upper bound for the latitude in decimal degrees
		private Decimal lomin; // lower bound for the longitude in decimal degrees
		private Decimal lomax; // upper bound for the longitude in decimal degrees
	}

	public static final List<OpenSkyEndpoint> apiEndpoints = new List<OpenSkyEndpoint>{
		new AllStateVectors()
	};

	/**
	 * Simple class that wraps information about the different endpoints we can talk to in the OpenSky API.
	 */
	private abstract class OpenSkyEndpoint {

		private String name;
		private String label;

		private OpenSkyEndpoint(String name, String label) {
			this.name = name;
			this.label = label;
		}

		private abstract List<valence.Field> getFields();

		private abstract String buildURL(valence.LinkContext context, OpenSkyAdapter.Configuration config);

		private abstract String getConfigurationStructure();

		private abstract String explainConfiguration(OpenSkyAdapter.Configuration config);

		private abstract List<valence.RecordInFlight> parseRecords(valence.JSONParse response);
	}

	private class AllStateVectors extends OpenSkyEndpoint {

		private Map<String, String> fields = new Map<String, String>{
			'icao24' => 'Unique ICAO 24-bit address of the transponder in hex string representation.',
			'callsign' => 'Callsign of the vehicle (8 chars). Can be null if no callsign has been received.',
			'origin_country' => 'Country name inferred from the ICAO 24-bit address.',
			'time_position' => 'Unix timestamp (seconds) for the last position update. Can be null if no position report was received by OpenSky within the past 15s.',
			'last_contact' => 'Unix timestamp (seconds) for the last update in general. This field is updated for any new, valid message received from the transponder.',
			'longitude' => 'WGS-84 longitude in decimal degrees. Can be null.',
			'latitude' => 'WGS-84 latitude in decimal degrees. Can be null.',
			'baro_altitude' => 'Barometric altitude in meters. Can be null.',
			'on_ground' => 'Boolean value which indicates if the position was retrieved from a surface position report.',
			'velocity' => 'Velocity over ground in m/s. Can be null.',
			'true_track' => 'True track in decimal degrees clockwise from north (north=0°). Can be null.',
			'vertical_rate' => 'Vertical rate in m/s. A positive value indicates that the airplane is climbing, a negative value indicates that it descends. Can be null.',
			'sensors' => 'IDs of the receivers which contributed to this state vector. Is null if no filtering for sensor was used in the request.',
			'geo_altitude' => 'Geometric altitude in meters. Can be null.',
			'squawk' => 'The transponder code aka Squawk. Can be null.',
			'spi' => 'Whether flight status indicates special purpose indicator.',
			'position_source' => 'Origin of this state’s position: 0 = ADS-B, 1 = ASTERIX, 2 = MLAT'
		};

		private AllStateVectors() {
			super('all_state_vectors', 'All State Vectors');
		}

		private override List<valence.Field> getFields() {

			List<valence.Field> fieldList = new List<valence.Field>();
			for(String key : fields.keySet()) {
				fieldList.add(valence.Field.create(key).withDescription(fields.get(key)).build());
			}
			return fieldList;
		}

		private override String buildURL(valence.LinkContext context, OpenSkyAdapter.Configuration config) {
			if(config.bounded)
				return '/states/all?lamin=' + config.lamin + '&lomin=' + config.lomin + '&lamax=' + config.lamax + '&lomax=' + config.lomax;
			else
				return '/states/all';
		}

		private override String getConfigurationStructure() {
			return JSON.serialize(new Map<String, Object>{
				'description' => 'This API endpoint supports an optional bounding box to only fetch flights inside that geographic area.',
				'fields' => new List <Map<String, Object>>{
					new Map<String, Object>{
						'name' => 'bounded',
						'attributes' => new Map<String, Object>{
							'label' => 'Boundaries Enabled',
							'type' => 'checkbox'
						}
					},
					new Map<String, Object>{
						'name' => 'lamin',
						'attributes' => new Map<String, Object>{
							'label' => 'Lower Latitude Bound'
						}
					},
					new Map<String, Object>{
						'name' => 'lamax',
						'attributes' => new Map<String, Object>{
							'label' => 'Upper Latitude Bound'
						}
					},
					new Map<String, Object>{
						'name' => 'lomin',
						'attributes' => new Map<String, Object>{
							'label' => 'Lower Longitude Bound'
						}
					},
					new Map<String, Object>{
						'name' => 'lomax',
						'attributes' => new Map<String, Object>{
							'label' => 'Upper Longitude Bound'
						}
					}
				}
			});
		}

		private override String explainConfiguration(OpenSkyAdapter.Configuration config) {
			if(config.bounded) {
				if(config.lamin != null && config.lomin != null && config.lamax != null && config.lomax != null &&
					config.lamin < config.lamax && config.lomin < config.lomax) {
					return 'Bounding geobox successfully configured.';
				}
				else {
					return '<span class="slds-text-color_error">Please configure longitude and latitude boundaries for this Link.</span>';
				}
			}
			else {
				return 'Boundaries are disabled, this Link will fetch all Flights.';
			}

		}

		private override List<valence.RecordInFlight> parseRecords(valence.JSONParse response) {

			List<valence.RecordInFlight> records = new List<valence.RecordInFlight>();

			for(valence.JSONParse stateVector : response.get('states').asList()) {
				List<valence.JSONParse> values = stateVector.asList();
				Map<String, Object> properties = new Map<String, Object>();

				for(String fieldName : fields.keySet()) {
					properties.put(fieldName, values.remove(0).getValue());
				}
				records.add(new valence.RecordInFlight(properties));
			}

			return records;
		}
	}
}