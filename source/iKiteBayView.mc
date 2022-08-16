using Toybox.WatchUi as Ui;
using Toybox.Graphics;
using Toybox.System as Sys;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;

class iKiteBayView extends Ui.View {
    hidden var mMessage = "Initializing";
    
    hidden var spaceFromTop = 15;
    hidden var mResponseData;

    hidden var displayMode = DISPLAY_MODE_NORMAL; // 0 - normal, 1 - tide
    hidden var currentSpot = 0; // Array index of current spot that is displayed

    function initialize() {
        Ui.View.initialize();
    }

    // Load your resources here
    function onLayout(dc) {
    }

    // Restore the state of the app and prepare the view to be shown
    function onShow() {
    }

    function onDisplayModeChange() {
        if (currentSpot == 0) {
            // only support change mode for 3rd avenue
            displayMode  = (displayMode + 1) % 2;
            Ui.requestUpdate();
        }
    }
    
    function onNextPage() {
        displayMode = 0;
        currentSpot = currentSpot+1;
        if (currentSpot > displaySpotList.size() - 1) {
            currentSpot = 0;
        }
        Ui.requestUpdate();
    }
    
    function onPreviousPage() {
        displayMode = 0;
        currentSpot = currentSpot-1;
        if (currentSpot<0) {
            currentSpot = displaySpotList.size() - 1;
        }
        Ui.requestUpdate();
    }
    
    function formatTideHeight(height) {
        if (height == null) {
            return "n/a";
        }
        return Lang.format("$1$ fts", [height.format("%.1f")]);
    }

    function formatMinOfDay(minOfDay) {
        if (minOfDay == null) {
            return "n/a";
        }
        var hour = minOfDay / 60;
        if (hour >= 24) {
            hour -= 24;
        }
        return Lang.format("$1$:$2$", [hour.format("%02d"), (minOfDay % 60).format("%02d")]);
    }

    function getTideDesc(tideData, currMinOfDay) {
        var currTideHeight = null;
        var nearbyTideEvent = null;
        for (var i = 0; i < tideData.size() - 1; i++) {
            var sT = tideData[i][0];
            var eT = tideData[i+1][0];
            if (currMinOfDay >= sT && currMinOfDay <= eT) {
                var sH = tideData[i][1];
                var eH = tideData[i+1][1];
                // linear calculation
                currTideHeight = sH + ((eH - sH) * ((currMinOfDay.toFloat() - sT) / (eT - sT)));
            }
            if (currTideHeight != null && tideData[i+1][2] != null) {
                nearbyTideEvent = tideData[i+1];
                break;
            }
        }
        if (nearbyTideEvent == null) {
            // curr time falls out of the tide data time range
            nearbyTideEvent = tideData[tideData.size() - 1];
            return Lang.format("$1$: $2$, $3$", [nearbyTideEvent[2], formatTideHeight(nearbyTideEvent[1]), formatMinOfDay(nearbyTideEvent[0])]);
        } else if (currTideHeight) {
            return Lang.format("$1$ -> $2$ , $3$", [currTideHeight.format("%.1f"), formatTideHeight(nearbyTideEvent[1]), formatMinOfDay(nearbyTideEvent[0])]);
        } else {
            return "Tide data unavailable";
        }
    }

    function getTimeStr(deviceWidth) {
        var info = Calendar.info(Time.now(), Time.FORMAT_LONG);
        if (deviceWidth >= FENIX_7X_WIDTH) {
            return Lang.format("$1$, $2$ $3$ $4$:$5$", [info.day_of_week, info.month, info.day, info.hour.format("%02d"), info.min.format("%02d")]).toUpper();
        } else {
            return Lang.format("$1$ $2$ $3$:$4$", [info.month, info.day, info.hour.format("%02d"), info.min.format("%02d")]).toUpper();
        }
    }

    function getWindDetailStr(lull, gust, unit, direction, deviceWidth) {
        if (deviceWidth >= FENIX_7X_WIDTH) {
            return Lang.format("$1$-$2$ $3$ $4$", [lull,  gust, unit, direction]);
        } else {
            return Lang.format("($1$-$2$) $3$", [lull,  gust, direction]);
        }

    }

    function parseData(data) {
        if (data == null) {
            return null;
        }

        var output = {};

        var now = Calendar.info(Time.now(), Time.FORMAT_SHORT);
        var currHr = now.hour;
        var currMin = now.min;

        for (var i = 0; i < data["data_values"].size(); i++) { 
            var spotData = data["data_values"][i];

            var mCurrentWind = null;
            var mLullWind = null;
            var mGustWind = null;
            var mUnitWind = null;
            var mUnitTemp = null;
            var mSpotNum = null;
            var mSpotName = null;
            var mCurrentWindDirection = null;
            var mTimestamp = null;
            var mLastUpdateTime = null;
            var mAirTemp = null;
            var mWindDesc = null;
            var mStatusMessage = null;

            var tideDesc = null;
            var tideHeights = null;

            if(spotData[19]) {
                mCurrentWind = (spotData[19].toFloat() + 0.5).toNumber();
            } else {
                mCurrentWind = "--";
            }
            
            mCurrentWindDirection = spotData[23];
            mUnitWind = data["units_wind"];
            mUnitTemp = data["units_temp"];
            if (spotData[20]) {
                mLullWind = spotData[20].toNumber();
            } else {
                mLullWind = "x";
            }
            if (spotData[21]) {
                mGustWind = spotData[21].toNumber();
            } else {
                System.println("Warning: Lull not available");
                mGustWind = "x";
            }
            
            mSpotNum = spotData[0];
            mSpotName = spotData[1];
            mTimestamp = spotData[18];
            mWindDesc = spotData[32];
            if (mTimestamp!=null && (mTimestamp.length()>17)) {
                var lastUpdateHr = mTimestamp.substring(11,13).toNumber();
                var lastUpdateMin = mTimestamp.substring(14,16).toNumber();
                mLastUpdateTime = (currHr - lastUpdateHr) * 60 + (currMin - lastUpdateMin);
            }
            
            if(spotData[24]) {
                mAirTemp = spotData[24].toNumber();
            } else {
                mAirTemp = null;
            }
        
            mStatusMessage = spotData[15];

            if (mSpotNum == THIRD_BEACH_STATION_NUM && data["tide"] != null) {
                tideHeights = data["tide"];
                tideDesc = getTideDesc(tideHeights, currHr * 60 + currMin);
            }

            output.put(mSpotNum, {
                "mCurrentWind" => mCurrentWind, "mLullWind" => mLullWind, "mGustWind" => mGustWind, "mUnitWind" => mUnitWind,
                "mUnitTemp" => mUnitTemp, "mSpotName" => mSpotName, "mCurrentWindDirection" => mCurrentWindDirection,
                "mTimestamp" => mTimestamp, "mLastUpdateTime" => mLastUpdateTime, "mAirTemp" => mAirTemp,
                "mStatusMessage" => mStatusMessage, "tideHeights" => tideHeights, "tideDesc" => tideDesc, "mWindDesc" => mWindDesc
                });
        }
        
        System.println("Parsed data: " + output);
        return output;
    }

    // Update the view
    function onUpdate(dc) {
        var spotData = null;
    
        if(mMessage == null && mResponseData["status"]["status_code"]==0) {
            spotData = parseData(mResponseData);
            mMessage = null;
          } else if (mMessage==null) {
            mMessage = "Error:"+mResponseData["status"]["status_message"];      
        }

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        if(mMessage) {
            dc.drawText(dc.getWidth()/2, dc.getHeight()/2, Graphics.FONT_TINY, mMessage, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
            var yPos = 15;

            // spot name
            dc.setColor(Graphics.COLOR_ORANGE, Graphics.COLOR_BLACK);
            var spotName = displaySpotList[currentSpot];
            dc.drawText(dc.getWidth()/2, yPos, Graphics.FONT_MEDIUM, spotName, Graphics.TEXT_JUSTIFY_CENTER);
            yPos += dc.getFontHeight(Graphics.FONT_MEDIUM);

            // line
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            dc.drawLine(0, yPos, dc.getWidth(), yPos);
            yPos += 10;

            var now = Calendar.info(Time.now(), Time.FORMAT_SHORT);
            var deviceWidth = dc.getWidth();
            // display normal mode 
            if (displayMode == DISPLAY_MODE_NORMAL) {
                ////////////////////////////////////  3rd avenue   ////////////////////////////////////
                if (currentSpot == 0) {
                    var windFont = Graphics.FONT_MEDIUM;
                    var windDetailFont = Graphics.FONT_TINY;
                    var windXpos = 20;
                    var windDetailXoffset = 25;
                    var windDetailYoffset = 6;
                    var lastUpdateTimeYOffset = 15;
                    if (deviceWidth < FENIX_7X_WIDTH) {
                        windFont = Graphics.FONT_SMALL;
                        windDetailFont = Graphics.FONT_SMALL;
                        windXpos = 15;
                        windDetailXoffset = 20;
                        windDetailYoffset = 0;
                        lastUpdateTimeYOffset = 8;
                    }
                    
                    for (var i = 0; i < 2; i++) {
                        var stationNum = THIRD_AVENUE_STATION_LIST[i][0];
                        var stationName = THIRD_AVENUE_STATION_LIST[i][1];
                        var stationData = spotData[stationNum];
                        var currWindStr = Lang.format("$1$: $2$", [stationName, stationData["mCurrentWind"]]);
                        dc.drawText(windXpos, yPos, windFont, currWindStr, Graphics.TEXT_JUSTIFY_LEFT);
                        var windDetailStr = getWindDetailStr(stationData["mLullWind"], stationData["mGustWind"], stationData["mUnitWind"], stationData["mCurrentWindDirection"], deviceWidth);
                        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
                        dc.drawText(dc.getTextWidthInPixels(currWindStr, windFont) + windDetailXoffset, yPos + windDetailYoffset, Graphics.FONT_TINY, windDetailStr, Graphics.TEXT_JUSTIFY_LEFT);
                        dc.drawText(dc.getWidth() - 25, yPos + lastUpdateTimeYOffset, Graphics.FONT_XTINY, stationData["mLastUpdateTime"], Graphics.TEXT_JUSTIFY_LEFT);
                        yPos += dc.getFontHeight(windFont);
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                    }

                    // line
                    dc.drawLine(0, yPos, dc.getWidth(), yPos);
                    yPos += 5;
                    
                    // tide
                    var tideDesc = spotData[THIRD_BEACH_STATION_NUM]["tideDesc"];
                    dc.drawText(dc.getWidth()/2, yPos, Graphics.FONT_TINY, tideDesc, Graphics.TEXT_JUSTIFY_CENTER);
                    yPos += dc.getFontHeight(Graphics.FONT_TINY) + 5;
                    
                    // line
                    dc.drawLine(0, yPos, dc.getWidth(), yPos);
                    yPos += 5;

                    // current time
                    dc.drawText(dc.getWidth()/2, yPos, Graphics.FONT_TINY, getTimeStr(deviceWidth), Graphics.TEXT_JUSTIFY_CENTER);
                    yPos += dc.getFontHeight(Graphics.FONT_TINY);

                    // air temp
                    var tempStr = Lang.format("$1$°$2$", [spotData[THIRD_BEACH_STATION_NUM]["mAirTemp"], spotData[THIRD_BEACH_STATION_NUM]["mUnitTemp"]]);
                    dc.drawText(dc.getWidth()/2, yPos, Graphics.FONT_TINY, tempStr, Graphics.TEXT_JUSTIFY_CENTER);
                } 
                ////////////////////////////////////  pond   ////////////////////////////////////
                else if (currentSpot == 1) {
                    for (var i = 0; i < 4; i++) {
                        var stationNum = POND_STATION_LIST[i][0];
                        var stationName = POND_STATION_LIST[i][1];

                        var stationData = spotData[stationNum];
                        var stationStr = Lang.format("$1$: $2$", [stationName, stationData["mWindDesc"].substring(0, stationData["mWindDesc"].find("s") + 1)]);
                        dc.drawText(20, yPos, Graphics.FONT_TINY, stationStr, Graphics.TEXT_JUSTIFY_LEFT);
                        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
                        dc.drawText(dc.getWidth() - 30, yPos + 10, Graphics.FONT_XTINY, stationData["mLastUpdateTime"], Graphics.TEXT_JUSTIFY_LEFT);
                        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
                        yPos += dc.getFontHeight(Graphics.FONT_TINY) + 5;
                    }

                    // line
                    dc.drawLine(0, yPos, dc.getWidth(), yPos);
                    yPos += 5;

                    // current time
                    dc.drawText(dc.getWidth()/2, yPos, Graphics.FONT_TINY, getTimeStr(deviceWidth), Graphics.TEXT_JUSTIFY_CENTER);
                    yPos += dc.getFontHeight(Graphics.FONT_TINY);

                    // air temp
                    var tempStr = Lang.format("$1$°$2$", [spotData[NASA_STATION_NUM]["mAirTemp"], spotData[NASA_STATION_NUM]["mUnitTemp"]]);
                    dc.drawText(dc.getWidth()/2, yPos, Graphics.FONT_TINY, tempStr, Graphics.TEXT_JUSTIFY_CENTER);
                }
            } 
            else if (displayMode == DISPLAY_MODE_TIDE) {
                var tideHeights = spotData[THIRD_BEACH_STATION_NUM]["tideHeights"];
                var tideDesc = spotData[THIRD_BEACH_STATION_NUM]["tideDesc"];
                var currHeight = tideDesc.substring(0, tideDesc.find(" "));

                // tide desc
                tideDesc = Lang.format("Now: $1$ fts , $2$:$3$", [currHeight, now.hour.format("%02d"), now.min.format("%02d")]);
                dc.drawText(dc.getWidth()/2, yPos, Graphics.FONT_TINY, tideDesc, Graphics.TEXT_JUSTIFY_CENTER);
                yPos += dc.getFontHeight(Graphics.FONT_TINY) + 5;

                // line
                dc.drawLine(0, yPos, dc.getWidth(), yPos);
                yPos += 5;

                // tide heights
                var currMin = now.hour * 60 + now.min;
                var j = 0;
                for (var i = 0; i < tideHeights.size(); i++) {
                    if (tideHeights[i][0] > currMin) {
                        tideDesc = Lang.format("$1$ , $2$", [formatTideHeight(tideHeights[i][1]), formatMinOfDay(tideHeights[i][0])]);
                        dc.drawText(dc.getWidth()/2, yPos, Graphics.FONT_TINY, tideDesc, Graphics.TEXT_JUSTIFY_CENTER);
                        yPos += dc.getFontHeight(Graphics.FONT_TINY);
                        j += 1;
                    }
                    if (j == 4) {
                        // can only display 5 rows
                        break;
                    }
                }
            }
        }
    }


    // Called from delegate whenever screen should be rendered
    // If data == null, just render the screen again (e.g. time updated)
    // If data == string, show the string message
    // If data == dictionary, render the data from the dictionary
    function renderUiWithData(data) {
        if (data instanceof Lang.String) {
            mMessage = data;
            System.println("Showing message: "+mMessage);
        }
        else if (data instanceof Dictionary) {
        
            mResponseData = data;
            mMessage = null;
    
        }
        Ui.requestUpdate();
    }
}
