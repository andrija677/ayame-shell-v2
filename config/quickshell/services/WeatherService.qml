import "../settings"
import QtQuick
import Quickshell
import Quickshell.Io
pragma Singleton

QtObject {
    id: root

    property var forecast: cache.forecast
    property var searchResults: []
    property bool loading: false
    property bool searching: false
    property string error: ""
    readonly property bool configured: ShellSettings.weatherEnabled && ShellSettings.weatherLocationName.length > 0
    readonly property bool hasData: forecast && forecast.current
    property Timer refreshTimer

    refreshTimer: Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: root.configured
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    property FileView cacheFile

    cacheFile: FileView {
        id: cacheFile

        path: Quickshell.cacheDir + "/weather.json"
        preload: true
        atomicWrites: true
        printErrors: false

        JsonAdapter {
            id: cache

            property var forecast: null
            property real updatedAt: 0
        }

    }

    function weatherLabel(code) {
        if (code === 0)
            return "Clear";

        if (code <= 3)
            return "Partly cloudy";

        if (code === 45 || code === 48)
            return "Foggy";

        if (code >= 51 && code <= 67)
            return "Rain";

        if (code >= 71 && code <= 77)
            return "Snow";

        if (code >= 80 && code <= 82)
            return "Showers";

        if (code >= 85 && code <= 86)
            return "Snow showers";

        if (code >= 95)
            return "Thunderstorm";

        return "Mixed conditions";
    }

    function searchCity(query) {
        const clean = query.trim();
        if (clean.length < 2)
            return ;

        searching = true;
        error = "";
        const request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return ;

            searching = false;
            if (request.status < 200 || request.status >= 300) {
                error = "Could not search locations";
                return ;
            }
            try {
                searchResults = (JSON.parse(request.responseText).results || []).slice(0, 5);
            } catch (exception) {
                error = "Invalid location response";
            }
        };
        request.open("GET", "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(clean) + "&count=5&language=en&format=json");
        request.send();
    }

    function selectLocation(location) {
        ShellSettings.weatherLocationName = location.name + (location.admin1 ? ", " + location.admin1 : "") + (location.country ? ", " + location.country : "");
        ShellSettings.weatherLatitude = location.latitude;
        ShellSettings.weatherLongitude = location.longitude;
        ShellSettings.weatherEnabled = true;
        searchResults = [];
        refresh();
    }

    function forgetLocation() {
        ShellSettings.weatherEnabled = false;
        ShellSettings.weatherLocationName = "";
        ShellSettings.weatherLatitude = 0;
        ShellSettings.weatherLongitude = 0;
        forecast = null;
        cache.forecast = null;
        cache.updatedAt = 0;
        cacheFile.writeAdapter();
    }

    function refresh() {
        if (!configured || loading)
            return ;

        loading = true;
        error = "";
        const url = "https://api.open-meteo.com/v1/forecast?latitude=" + ShellSettings.weatherLatitude + "&longitude=" + ShellSettings.weatherLongitude + "&current=temperature_2m,apparent_temperature,is_day,weather_code,wind_speed_10m" + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max" + "&timezone=auto&forecast_days=5&temperature_unit=" + ShellSettings.weatherTemperatureUnit;
        const request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE)
                return ;

            loading = false;
            if (request.status < 200 || request.status >= 300) {
                error = hasData ? "Offline • showing cached weather" : "Weather unavailable";
                return ;
            }
            try {
                forecast = JSON.parse(request.responseText);
                cache.forecast = forecast;
                cache.updatedAt = Date.now();
                cacheFile.writeAdapter();
            } catch (exception) {
                error = "Invalid forecast response";
            }
        };
        request.open("GET", url);
        request.send();
    }

}
