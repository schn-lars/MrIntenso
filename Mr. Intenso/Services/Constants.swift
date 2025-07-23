import Foundation

/**
    This document contains any constants or default values we use in the application.
 */

struct Constants {
    static let LOCATION_THRESHOLD = 0.3 // in meters
    static let MASK_HEIGHT = 640
    static let MASK_WIDTH = 640
    
    // MARK: Defaults
    static let FACE_SIMILARITY_THRESHOLD_DEFAULT: Float = 0.05
    static let SEGMENTATION_THRESHOLD_DEFAULT: Float = 0.7
    static let IOU_THRESHOLD_DEFAULT: Float = 0.5
    static let LANGUAGE_DEFAULT: String = languages[LanguageTitle.ENGLISH]!
    static let AUTO_SAVE_DEFAULT: Bool = false
    static let JOKE_DEFAULT: String = "neutral"
    static let MAX_CACHE_SIZE: Int = 100
    
    // MARK: Classification classes
    private static let classes: [Int : String] =
        [0: "person",           // Joke
         1: "bicycle",          // GoogleLens
         2: "car",              // GoogleLens
         3: "motorcycle",       // GoogleLens
         4: "airplane",         // GoogleLens
         5: "bus",              // GoogleLens
         6 : "train",           // GoogleLens
         7: "truck",            // GoogleLens
         8: "boat",             // GoogleLens
         9: "trafficlight",
         10: "firehydrant",
         11: "stopsign",
         12: "parkingmeter",
         13: "bench",
         14: "bird",            // Classify, Occurrence, Missing, Wikipedia
         15: "cat",             // Wikipedia
         16: "dog",             // Wikipedia
         17: "horse",           // Wikipedia
         18: "sheep",           // Wikipedia
         19: "cow",             // Wikipedia
         20: "elephant",        // Wikipedia
         21: "bear",            // Wikipedia
         22: "zebra",           // Wikipedia
         23: "giraffe",         // Wikipedia
         24: "backpack",        // GoogleLens
         25: "umbrella",        // GoogleLens
         26: "handbag",         // GoogleLens
         27: "tie",             // GoogleLens
         28: "suitcase",        // GoogleLens
         29: "frisbee",         // GoogleLens
         30: "skis",            // GoogleLens
         31: "snowboard",       // GoogleLens
         32: "sportsball",     // GoogleLens
         33: "kite",            // GoogleLens
         34: "baseballbat",    // GoogleLens
         35: "baseballglove",  // GoogleLens
         36: "skateboard",      // GoogleLens
         37: "surfboard",       // GoogleLens
         38: "tennisracket",
         39: "bottle",          // GoogleLens
         40: "wineglass",      // GoogleLens
         41: "cup",             // GoogleLens
         42: "fork",
         43: "knife",
         44: "spoon",
         45: "bowl",
         46: "banana",          // Wikipedia
         47: "apple",           // Wikipedia
         48: "sandwich",        // Wikipedia
         49: "orange",          // Wikipedia
         50: "broccoli",        // Wikipedia
         51: "carrot",          // Wikipedia
         52: "hotdog",         // Wikipedia
         53: "pizza",           // Wikipedia
         54: "donut",           // Wikipedia
         55: "cake",            // Wikipedia
         56: "chair",           // GoogleLens
         57: "couch",           // GoogleLens
         58: "pottedplant",
         59: "bed",             // GoogleLens
         60: "diningtable",    // GoogleLens
         61: "toilet",
         62: "tv",              // GoogleLens
         63: "laptop",          // GoogleLens
         64: "mouse",           // GoogleLens
         65: "remote",          // GoogleLens
         66: "keyboard",        // GoogleLens
         67: "cellphone",      // GoogleLens
         68: "microwave",       // GoogleLens
         69: "oven",            // GoogleLens
         70: "toaster",         // GoogleLens
         71: "sink",
         72: "refrigerator",
         73: "book",            // GoogleLens
         74: "clock",           // GoogleLens
         75: "vase",
         76: "scissors",
         77: "teddybear",
         78: "hairdrier",
         79: "toothbrush",
         80: "poster"           // Location, Navigation
        ]                       // For all: Weather, Past-Objects, Shazam, QR-Code
    
    private static let klassen: [Int : String] =
        [0: "Mensch",
         1: "Fahrrad",
         2: "Auto",
         3: "Motorrad",
         4: "Flugzeug",
         5: "Bus",
         6: "Zug",
         7: "Lastwagen",
         8: "Boot",
         9: "Ampel",
         10: "Hydrant",
         11: "Stop-Schild",
         12: "Parking-Meter",
         13: "Bank",
         14: "Vogel",
         15: "Katze",
         16: "Hund",
         17: "Pferd",
         18: "Schaf",
         19: "Kuh",
         20: "Elefant",
         21: "Bär",
         22: "Zebra",
         23: "Giraffe",
         24: "Rucksack",
         25: "Regenschirm",
         26: "Handtasche",
         27: "Krawatte",
         28: "Koffer",
         29: "Frisbee",
         30: "Ski",
         31: "Snowboard",
         32: "Ball",
         33: "Drachen",
         34: "Baseball Schläger",
         35: "Baseball Handschuh",
         36: "Skateboard",
         37: "Surfbrett",
         38: "Tennis Schläger",
         39: "Flasche",
         40: "Weinglas",
         41: "Tasse",
         42: "Gabel",
         43: "Messer",
         44: "Löffel",
         45: "Schüssel",
         46: "Banane",
         47: "Apfel",
         48: "Sandwich",
         49: "Orange",
         50: "Broccoli",
         51: "Karotte",
         52: "Hot dog",
         53: "Pizza",
         54: "Donut",
         55: "Kuchen",
         56: "Stuhl",
         57: "Sofa",
         58: "Pflanze",
         59: "Bett",
         60: "Esstisch",
         61: "Toilette",
         62: "Fernseher",
         63: "Laptop",
         64: "Maus",
         65: "remote",
         66: "Tastatur",
         67: "Smartphone",
         68: "Mikrowelle",
         69: "Ofen",
         70: "Toaster",
         71: "Lavabo",
         72: "Kühlschrank",
         73: "Buck",
         74: "Uhr",
         75: "Vase",
         76: "Schere",
         77: "Teddybär",
         78: "Föhn",
         79: "Zahnbürste",
         80: "Poster"
        ]
    
    static func getAnimals() -> [String] {
        return ["cat", "dog", "bird", "horse", "sheep", "cow", "elephant", "bear", "zebra", "giraffe"]
    }
    
    static func getClass(from idx: Int) -> String {
        return classes[idx] ?? "No known class."
    }
    
    static func getClassIdx(from cls: String) -> Int {
        return classes.first(where: { $0.value == cls })?.key ?? 0
    }
    
    static func getTranslatedLanguage(for className: String) -> String {
        guard UserDefaults.standard.string(forKey: UserDefaultsKeys.LANGUAGE.rawValue) == "GER" else {
            return className
        }
        
        return klassen[getClassIdx(from: className)] ?? "No known class."
    }
    
    // MARK: Language
    private static let languages: [LanguageTitle : String] =
        [LanguageTitle.ENGLISH: "ENG",
         LanguageTitle.GERMAN: "GER"
        ]
    
    static func getLanguages() -> [String] {
        return Array(languages.values)
    }
    
    // MARK: Jokes
    private static let jokeSettings: [String] = ["neutral", "chuck", "all"]
    
    static func getJokeSettings() -> [String] {
        return jokeSettings
    }
    
    // https://stackoverflow.com/questions/53318973/check-whether-device-is-connected-to-a-vpn-in-ios-12
    
    static func isConnectedToVPN() -> Bool {
        guard let cfDict = CFNetworkCopySystemProxySettings() else {
            return false
        }
        
        let nsDict = cfDict.takeRetainedValue() as NSDictionary
        guard let scoped = nsDict["__SCOPED__"] as? [String: Any] else {
            return false
        }
        
        for key in scoped.keys {
            if key.contains("tap") || key.contains("tun") || key.contains("ppp") || key.contains("ipsec") || key.contains("utun") {
                return true
            }
        }
        
        return false
    }
}

struct TranslationUnit {
    static func getMessage(for type: NotificationType) -> String? {
        let language = UserDefaults.standard.string(forKey: UserDefaultsKeys.LANGUAGE.rawValue) ?? "ENG"
        switch language {
        case "ENG":
            switch type {
            case .SELECT_MASK:
                return "Select a mask"
            case .INFERENCE_FPS:
                return "Speed %.1f ms, %.f FPS"
            case .NO_INTERNET:
                return "No internet connection!"
            case .VERSION_STATUS_OK:
                return "App is up to date."
            case .INVALID_MASK_SELECTION:
                return "Invalid mask selected."
            case .AUTO_DOWNLOAD:
                return "Auto-download image"
            case .SEGMENTATION_THRESHOLD:
                return "Segmentation threshold"
            case .IOU_THRESHOLD:
                return "IOU-threshold"
            case .LANGUAGE:
                return "Language"
            case .JOKE:
                return "Jokes"
            case .REVERSE_SEARCH:
                return "GoogleLens-Search"
            case .RESET_ALL:
                return "Reset all"
            case .RESET_ALL_DESCRIPTION:
                return "Are you sure you want to reset the entire app? This operation cannot be undone."
            case .RESET_CACHE:
                return "Reset cache"
            case .RESET_BASKET:
                return "Reset shopping-basket"
            case .RESET_BASKET_DESCRIPTION:
                return "Are you sure you want to reset the entire shopping-basket? This operation cannot be undone."
            case .RESET_CACHE_DESCRIPTION:
                return "Are you sure you want to reset the entire cache? This operation cannot be undone."
            case .OPTION_RESET:
                return "Reset"
            case .OPTION_DISMISS:
                return "Cancel"
            case .GOOGLE_LENS_NO_OBJECTS_FOUND:
                return "No visual matches have been returned!"
            case .GOOGLE_LENS_RELATED_TITLE:
                return "Related Content"
            case .GOOGLE_LENS_REVIEWS:
                return "%d reviews"
            case .SHARE_SCAN:
                return "Share this information by letting a friend scan it!"
            case .SHARE_FAILED:
                return "Unable to share the object!"
            case .SHARE_LOADING:
                return "Creating Code..."
            case .BASKET_EMPTY:
                return "Your shopping-basket is empty."
            case .BASKET_SORT_BY:
                return "Sort by:"
            case .PATCH_NOTES:
                return "Patch Notes"
            case .CLOSE_PATCH_NOTES:
                return "Thank you!"
            case .INFO_PROCESS_COMPLETE:
                return "Information-Retrieval process completed!"
            case .INFO_PROCESSING:
                return "Processed %d/%d"
            case .CACHE_FULL_ERROR:
                return "This object will be deleted, unless you favorize it! Favorizing it causes oldest object to get deleted."
            case .SETTINGS_TITLE:
                return "Settings"
            case .SHAZAM_UNKNOWN_TITLE:
                return "Unknown title"
            case .SHAZAM_UNKNOWN_ARTIST:
                return "Unknown artist"
            case .WEATHER_HOURLY_FORECAST_CITY:
                return "24h-forecast of %@"
            case .WEATHER_HOURLY_FORECAST:
                return "24h-forefast"
            case .WEATHER_MINUTELY_FORECAST:
                return "60min-Forecast"
            case .WEATHER_MINUTELY_FORECAST_CITY:
                return "60min-Forecast for %@"
            case .WEATHER_LONGTERM:
                return "Longterm forecast"
            case .WEATHER_LONGTERM_CITY:
                return "Longterm forecast for %@"
            case .WEATHER_TITLE:
                return "Local Weather"
            case .SHAZAM_TITLE:
                return "Music"
            case .ANIMAL_LOST_TITLE:
                return "Lost Animals"
            case .POSTER_TITLE_TEXT:
                return "Website"
            case .NAVIGATION_TITLE:
                return "Navigation"
            case .LOCATION_TITLE:
                return "Location"
            case .BIRD_CLASSIFICATION_TITLE:
                return "Species"
            case .BIRD_OCCURRENCES_TITLE:
                return "Occurrences"
            case .PERSON_CONVERSATION_TITLE:
                return "Conversation-Starter"
            case .WEATHER_SOURCE:
                return "Other sources"
            case .WEATHER_ANNOTATION:
                return "Weather data by Apple"
            case .GOOGLE_LENS_TITLE:
                return "Google Lens"
            case .BASKET_TITLE:
                return "Shopping Basket"
            case .BASKET_SOURCE_TITLE:
                return "Source"
            case .BASKET_CONDITION_TITLE:
                return "Condition"
            case .BASKET_INSTOCK_TITLE:
                return "In Stock"
            case .NO:
                return "No"
            case .YES:
                return "Yes"
            case .BASKET_REVIEWS_TITLE:
                return "Reviews"
            case .BASKET_RATING_TITLE:
                return "Rating"
            case .POSTER_TITLE_DATE:
                return "Date"
            case .DATE_SUGGESTED_TITLE:
                return "Suggested events"
            case .DATE_SAVED_TITLE:
                return "Saved events"
            case .DATE_DESCRIPTION_TITLE:
                return "Description"
            case .DATE_START_TITLE:
                return "Start"
            case .DATE_END_TITLE:
                return "End"
            case .DATE_LOCATION_TITLE:
                return "Location"
            case .DATE_TITLE_TITLE:
                return "Title"
            case .DATE_TITLE_DESCRIPTION:
                return "Name of the event"
            case .DATE_TITLE:
                return "Calendar"
            case .DATE_LOCATION_DESCRIPTION:
                return "Address, City or zip"
            case .DATE_CUSTOM_TITLE:
                return "Create an event"
            case .DATE_DESCRIPTION_DESCRIPTION:
                return "Additional notes"
            case .HOW_TO_DESCRIPTION:
                return "User Guide"
            case .HOW_TO_TITLE:
                return "Help"
            case .DESTINATION_WEATHER_TITLE:
                return "Weather at destination"
            case .WEATHER_CURRENT_TITLE:
                return "Current weather"
            }
        case "GER":
            switch type {
            case .SELECT_MASK:
                return "Wähle eine Maske aus"
            case .INFERENCE_FPS:
                return "Inferenz %.1f ms, %.f FPS"
            case .NO_INTERNET:
                return "Keine Internetverbindung!"
            case .VERSION_STATUS_OK:
                return "App ist auf dem neuesten Stand."
            case .INVALID_MASK_SELECTION:
                return "Ungültige Maske ausgewählt."
            case .AUTO_DOWNLOAD:
                return "Bilder herunteraden"
            case .SEGMENTATION_THRESHOLD:
                return "Segmentier-Wert"
            case .IOU_THRESHOLD:
                return "IOU-Wert"
            case .LANGUAGE:
                return "Sprache"
            case .JOKE:
                return "Witze"
            case .REVERSE_SEARCH:
                return "GoogleLens-Suche"
            case .RESET_ALL:
                return "Alles zurücksetzen"
            case .RESET_ALL_DESCRIPTION:
                return "Bist Du dir sicher, dass du die App zurücksetzen möchtest? Diese Operation kann nicht rückgängig gemacht werden."
            case .RESET_BASKET:
                return "Warenkorb zurücksetzen"
            case .RESET_BASKET_DESCRIPTION:
                return "Bist Du dir sicher, dass du den gesamten Warenkorb zurücksetzen möchtest? Diese Operation kann nicht rückgängig gemacht werden."
            case .RESET_CACHE:
                return "Cache zurücksetzen"
            case .RESET_CACHE_DESCRIPTION:
                return "Bist Du dir sicher, dass du den gesamten Cache zurücksetzen möchtest? Diese Operation kann nicht rückgängig gemacht werden."
            case .OPTION_RESET:
                return "Zurücksetzen"
            case .OPTION_DISMISS:
                return "Abbrechen"
            case .GOOGLE_LENS_NO_OBJECTS_FOUND:
                return "GoogleLens konnte keine Objekte erkennen!"
            case .GOOGLE_LENS_RELATED_TITLE:
                return "Ähnliche Resultate"
            case .GOOGLE_LENS_REVIEWS:
                return "%d Bewertungen"
            case .SHARE_SCAN:
                return "Lass einen Freund den Code scannen und teile Deine Informationen!"
            case .SHARE_FAILED:
                return "Fehler beim Erstellen des Codes."
            case .SHARE_LOADING:
                return "Code wird erstellt..."
            case .BASKET_EMPTY:
                return "Dein Warenkorb ist leer."
            case .BASKET_SORT_BY:
                return "Sortieren nach:"
            case .PATCH_NOTES:
                return "Neuerungen"
            case .CLOSE_PATCH_NOTES:
                return "Vielen Dank!"
            case .INFO_PROCESS_COMPLETE:
                return "Informations-Beschaffung abgeschlossen!"
            case .INFO_PROCESSING:
                return "%d/%d abgeschlossen"
            case .CACHE_FULL_ERROR:
                return "Das Objekt wird gelöscht, sofern Du es nicht favorisierst! Dies löscht jedoch das älteste Objekt."
            case .SETTINGS_TITLE:
                return "Einstellungen"
            case .SHAZAM_UNKNOWN_TITLE:
                return "Unbekannter Titel"
            case .SHAZAM_UNKNOWN_ARTIST:
                return "Unbekannter Interpret"
            case .WEATHER_HOURLY_FORECAST_CITY:
                return "24h-Vorhersage für %@"
            case .WEATHER_HOURLY_FORECAST:
                return "24h-Vorhersage"
            case .WEATHER_MINUTELY_FORECAST:
                return "60min-Vorhersage"
            case .WEATHER_MINUTELY_FORECAST_CITY:
                return "60min-Vorhersage für %@"
            case .WEATHER_LONGTERM_CITY:
                return "Langzeit-Prognose für %@"
            case .WEATHER_LONGTERM:
                return "Langzeit-Prognose"
            case .WEATHER_TITLE:
                return "Lokales Wetter"
            case .SHAZAM_TITLE:
                return "Musik"
            case .ANIMAL_LOST_TITLE:
                return "Vermisste Tiere"
            case .POSTER_TITLE_TEXT:
                return "Webseite"
            case .NAVIGATION_TITLE:
                return "Navigation"
            case .LOCATION_TITLE:
                return "Standort"
            case .BIRD_CLASSIFICATION_TITLE:
                return "Spezies"
            case .BIRD_OCCURRENCES_TITLE:
                return "Sichtungen"
            case .PERSON_CONVERSATION_TITLE:
                return "Conversation-Starter"
            case .WEATHER_SOURCE:
                return "Andere Quellen"
            case .WEATHER_ANNOTATION:
                return "Wetter-Daten von Apple"
            case .GOOGLE_LENS_TITLE:
                return "Google Lens"
            case .BASKET_TITLE:
                return "Warenkorb"
            case .BASKET_SOURCE_TITLE:
                return "Quelle"
            case .BASKET_CONDITION_TITLE:
                return "Zustand"
            case .BASKET_INSTOCK_TITLE:
                return "Auf Lager"
            case .NO:
                return "Nein"
            case .YES:
                return "Ja"
            case .BASKET_REVIEWS_TITLE:
                return "Bewertungen"
            case .BASKET_RATING_TITLE:
                return "Rezessionen"
            case .POSTER_TITLE_DATE:
                return "Datum"
            case .DATE_SUGGESTED_TITLE:
                return "Vorgeschlagene Events"
            case .DATE_SAVED_TITLE:
                return "Gemerkte Events"
            case .DATE_DESCRIPTION_TITLE:
                return "Beschreibung"
            case .DATE_START_TITLE:
                return "Start"
            case .DATE_END_TITLE:
                return "Ende"
            case .DATE_LOCATION_TITLE:
                return "Standort"
            case .DATE_TITLE_TITLE:
                return "Titel"
            case .DATE_TITLE_DESCRIPTION:
                return "Name des Events"
            case .DATE_TITLE:
                return "Kalender"
            case .DATE_LOCATION_DESCRIPTION:
                return "Adresse, Ort"
            case .DATE_CUSTOM_TITLE:
                return "Erstelle einen Event"
            case .DATE_DESCRIPTION_DESCRIPTION:
                return "Zusätzliche Notizen"
            case .HOW_TO_DESCRIPTION:
                return "Anleitung"
            case .HOW_TO_TITLE:
                return "Hilfe"
            case .DESTINATION_WEATHER_TITLE:
                return "Wetter am Zielort"
            case .WEATHER_CURRENT_TITLE:
                return "Aktuelle Lage"
            }
        default:
            print("TranslationUnit: Invalid language code provided = \(language)")
            return nil
        }
    }
}

/**
    This enum captures the different kinds of categories of any Notification used within the app.
 */
enum NotificationType {
    case YES
    case NO
    case SELECT_MASK
    case INFERENCE_FPS
    case NO_INTERNET
    case VERSION_STATUS_OK // no new version is up
    case INVALID_MASK_SELECTION
    case PATCH_NOTES
    case CLOSE_PATCH_NOTES
    case INFO_PROCESS_COMPLETE
    case INFO_PROCESSING
    case SETTINGS_TITLE
    
    // Errors
    case CACHE_FULL_ERROR
    
    
    // Settings
    case AUTO_DOWNLOAD
    case SEGMENTATION_THRESHOLD
    case IOU_THRESHOLD
    case LANGUAGE
    case JOKE
    case REVERSE_SEARCH
    
    case RESET_ALL
    case RESET_ALL_DESCRIPTION
    case RESET_BASKET
    case RESET_BASKET_DESCRIPTION
    case RESET_CACHE
    case RESET_CACHE_DESCRIPTION
    
    case HOW_TO_DESCRIPTION
    case HOW_TO_TITLE
    
    case OPTION_RESET
    case OPTION_DISMISS
    
    // Objects
    case GOOGLE_LENS_NO_OBJECTS_FOUND
    case GOOGLE_LENS_RELATED_TITLE
    case GOOGLE_LENS_REVIEWS
    case GOOGLE_LENS_TITLE
    
    case ANIMAL_LOST_TITLE
    
    case LOCATION_TITLE
    
    case BIRD_CLASSIFICATION_TITLE
    case BIRD_OCCURRENCES_TITLE
    
    case PERSON_CONVERSATION_TITLE
    
    case POSTER_TITLE_TEXT
    case POSTER_TITLE_DATE
    
    case NAVIGATION_TITLE
    
    case SHARE_SCAN
    case SHARE_LOADING
    case SHARE_FAILED
    
    case BASKET_SORT_BY
    case BASKET_EMPTY
    case BASKET_TITLE
    case BASKET_SOURCE_TITLE
    case BASKET_CONDITION_TITLE
    case BASKET_INSTOCK_TITLE
    case BASKET_REVIEWS_TITLE
    case BASKET_RATING_TITLE
    
    case SHAZAM_UNKNOWN_TITLE
    case SHAZAM_UNKNOWN_ARTIST
    case SHAZAM_TITLE
    
    case WEATHER_HOURLY_FORECAST_CITY
    case WEATHER_HOURLY_FORECAST
    case WEATHER_MINUTELY_FORECAST_CITY
    case WEATHER_MINUTELY_FORECAST
    case WEATHER_LONGTERM
    case WEATHER_LONGTERM_CITY
    case WEATHER_CURRENT_TITLE
    case WEATHER_TITLE
    case WEATHER_SOURCE
    case DESTINATION_WEATHER_TITLE
    case WEATHER_ANNOTATION
    
    case DATE_TITLE
    case DATE_SUGGESTED_TITLE
    case DATE_SAVED_TITLE
    case DATE_DESCRIPTION_TITLE
    case DATE_START_TITLE
    case DATE_END_TITLE
    case DATE_LOCATION_TITLE
    case DATE_TITLE_TITLE
    case DATE_TITLE_DESCRIPTION
    case DATE_LOCATION_DESCRIPTION
    case DATE_CUSTOM_TITLE
    case DATE_DESCRIPTION_DESCRIPTION
}
