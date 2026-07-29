pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    readonly property string apiKey: Config.options.bar.weather.apiKey
    property bool gpsActive: Config.options.bar.weather.enableGPS

    property double lat: 0
    property double lon: 0
    property bool locationReady: false

    onUseUSCSChanged: root.getData()
    onCityChanged: {
        if (root.city.length > 0) {
            root.searchCity(root.city);
        }
    }
    onGpsActiveChanged: {
        if (!root.gpsActive) {
            positionSource.stop();
            root.locationReady = false;
            if (root.city.length > 0) {
                root.searchCity(root.city);
            }
        } else {
            positionSource.start();
        }
    }

    property var data: ({
        uv: 0,
        humidity: 0,
        sunrise: 0,
        sunset: 0,
        windDir: 0,
        wCode: 0,
        city: 0,
        description: 0,
        wind: 0,
        precip: 0,
        visib: 0,
        press: 0,
        temp: 0,
        tempFeelsLike: 0,
        cr: 0,
        lastRefresh: 0,
    })

    function searchCity(query) {
        if (!root.apiKey || root.apiKey.length === 0) return;
        const url = `https://api.weather.com/v3/location/search?query=${encodeURIComponent(query)}&language=en-US&format=json&apiKey=${root.apiKey}`;
        citySearcher.command = ["bash", "-c", `curl -s "${url}"`];
        citySearcher.running = true;
    }

    function refineData(data) {
        let temp = {};
        temp.uv = data?.uvIndex ?? 0;
        temp.humidity = (data?.relativeHumidity ?? 0) + "%";
        temp.sunrise = formatTime(data?.sunriseTimeLocal) ?? "--:--";
        temp.sunset = formatTime(data?.sunsetTimeLocal) ?? "--:--";
        temp.windDir = data?.windDirectionCardinal ?? "N";
        temp.wCode = mapIconCode(data?.iconCode ?? 2000);
        temp.city = root.city || "City";
        temp.description = data?.wxPhraseLong ?? "";
        temp.cr = (data?.precip24Hour ?? 0) + "%";
        temp.temp = "";
        temp.tempFeelsLike = "";
        if (root.useUSCS) {
            temp.wind = (data?.windSpeed ?? 0) + " mph";
            temp.precip = (data?.precip24Hour ?? 0) + " in";
            temp.visib = (data?.visibility ?? 0) + " mi";
            temp.press = (data?.pressureMeanSeaLevel ?? 0) + " hPa";
            temp.temp += Math.round((data?.temperature ?? 0) * 9/5 + 32);
            temp.tempFeelsLike += Math.round((data?.temperatureFeelsLike ?? 0) * 9/5 + 32);
            temp.temp += "°F";
            temp.tempFeelsLike += "°F";
        } else {
            temp.wind = (data?.windSpeed ?? 0) + " km/h";
            temp.precip = (data?.precip24Hour ?? 0) + " mm";
            temp.visib = (data?.visibility ?? 0) + " km";
            temp.press = (data?.pressureMeanSeaLevel ?? 0) + " hPa";
            temp.temp += (data?.temperature ?? 0);
            temp.tempFeelsLike += (data?.temperatureFeelsLike ?? 0);
            temp.temp += "°C";
            temp.tempFeelsLike += "°C";
        }
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        root.data = temp;
    }

    function formatTime(isoString) {
        if (!isoString) return null;
        try {
            const d = new Date(isoString);
            let h = d.getHours();
            const m = d.getMinutes().toString().padStart(2, '0');
            const ampm = h >= 12 ? 'PM' : 'AM';
            h = h % 12 || 12;
            return `${h}:${m} ${ampm}`;
        } catch(e) {
            return null;
        }
    }

    function mapIconCode(code) {
        if (code >= 0 && code <= 3) return "113";
        if (code >= 4 && code <= 7) return "116";
        if (code >= 8 && code <= 10) return "119";
        if (code >= 11 && code <= 14) return "122";
        if (code >= 15 && code <= 17) return "200";
        if (code >= 18 && code <= 20) return "263";
        if (code >= 21 && code <= 23) return "266";
        if (code >= 24 && code <= 26) return "311";
        if (code >= 27 && code <= 29) return "296";
        if (code >= 30 && code <= 34) return "308";
        if (code >= 35 && code <= 37) return "389";
        if (code >= 38 && code <= 40) return "392";
        if (code >= 41 && code <= 42) return "395";
        if (code >= 43 && code <= 46) return "395";
        if (code >= 47 && code <= 49) return "176";
        if (code >= 50 && code <= 51) return "296";
        if (code >= 52 && code <= 54) return "302";
        if (code >= 55 && code <= 57) return "308";
        if (code >= 58 && code <= 60) return "359";
        if (code >= 61 && code <= 63) return "356";
        if (code >= 64 && code <= 65) return "362";
        if (code >= 66 && code <= 67) return "368";
        if (code >= 68 && code <= 70) return "374";
        if (code >= 71 && code <= 73) return "326";
        if (code >= 74 && code <= 75) return "329";
        if (code >= 76 && code <= 77) return "332";
        if (code >= 78 && code <= 80) return "320";
        if (code >= 81 && code <= 82) return "305";
        if (code >= 83 && code <= 84) return "365";
        if (code >= 85 && code <= 86) return "377";
        if (code >= 87 && code <= 89) return "395";
        if (code >= 90 && code <= 99) return "395";
        return "113";
    }

    function getData() {
        if (!root.locationReady || !root.apiKey) return;
        const units = root.useUSCS ? "e" : "m";
        const url = `https://api.weather.com/v3/wx/observations/current?geocode=${root.lat},${root.lon}&language=en-US&units=${units}&format=json&apiKey=${root.apiKey}`;
        fetcher.command = ["bash", "-c", `curl -s "${url}"`];
        fetcher.running = true;
    }

    Component.onCompleted: {
        if (root.gpsActive) {
            console.info("[WeatherService] Starting GPS service.");
            positionSource.start();
        } else if (root.city.length > 0) {
            root.searchCity(root.city);
        }
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return;
                try {
                    const parsedData = JSON.parse(text);
                    root.refineData(parsedData);
                } catch (e) {
                    console.error(`[WeatherService] ${e.message}`);
                }
            }
        }
    }

    Process {
        id: citySearcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0) return;
                try {
                    const parsed = JSON.parse(text);
                    const loc = parsed?.location;
                    if (loc?.latitude?.[0] && loc?.longitude?.[0]) {
                        root.lat = loc.latitude[0];
                        root.lon = loc.longitude[0];
                        root.locationReady = true;
                        root.getData();
                    }
                } catch (e) {
                    console.error(`[WeatherService:CitySearch] ${e.message}`);
                }
            }
        }
    }

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval

        onPositionChanged: {
            if (position.latitudeValid && position.longitudeValid) {
                root.lat = position.coordinate.latitude;
                root.lon = position.coordinate.longitude;
                root.locationReady = true;
                root.getData();
            } else {
                console.error("[WeatherService] Failed to get GPS location.");
            }
        }

        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop();
                root.locationReady = false;
                root.gpsActive = false;
                Quickshell.execDetached(["notify-send", Translation.tr("Weather Service"), Translation.tr("Cannot find a GPS service. Using city fallback."), "-a", "Shell"]);
                console.error("[WeatherService] Could not acquire valid backend.");
            }
        }
    }

    Timer {
        running: root.locationReady && !root.gpsActive
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: true
        onTriggered: root.getData()
    }
}
