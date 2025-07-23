import Foundation
import SwiftUI
import EventKit
import MapKit

/**
    This View is being used my the Calendar-Description.
 */

struct DateView: View {
    let eventStore = EKEventStore()
    
    @ObservedObject var eventList: EventList
    @State private var customTitle: String = ""
    @State private var customStart: Date = Date().addingTimeInterval(300)
    @State private var customEnd: Date = Date().addingTimeInterval(2100)
    @State private var customDescription: String = ""
    @State private var customAdress: String = ""
    @State private var customLocation: Location? = nil
    
    @State private var isSaving: Bool = false
    @State private var fetchingLocation: Bool = false
    
    @EnvironmentObject private var appViewModel: AppViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 5) {
                // Suggested dates
                if eventList.events.count(where: { !$0.saved && !inPast(date: $0.start) }) > 0 {
                    VStack(spacing: 5) {
                        HStack(alignment: .center) {
                            Text(TranslationUnit.getMessage(for: .DATE_SUGGESTED_TITLE) ?? "Suggested events")
                        }
                        .foregroundStyle(Color.black)
                        .font(.title)
                        
                        Divider()
                        
                        // each event needs a box
                        ForEach(eventList.events.indices, id: \.self) { index in
                            if !eventList.events[index].saved && !inPast(date: eventList.events[index].start) {
                                createSuggestedBox(for: $eventList.events[index])
                                    .background(Color.yellow.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
                
                // Saved Dates
                if eventList.events.count(where: { $0.saved && !inPast(date: $0.start) }) > 0 {
                    VStack(spacing: 5) {
                        HStack(alignment: .center) {
                            Text(TranslationUnit.getMessage(for: .DATE_SAVED_TITLE) ?? "Saved events")
                        }
                        .foregroundStyle(Color.black)
                        .font(.title)
                        
                        // each event needs a box
                        ForEach(eventList.events.indices, id: \.self) { index in
                            if eventList.events[index].saved && !inPast(date: eventList.events[index].start) {
                                Divider()
                                createSavedBox(for: $eventList.events[index])
                                    .background(Color.mint.opacity(0.1))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(.bottom, 10)
                }
                
                VStack(spacing: 5) {
                    HStack(alignment: .center) {
                        Text(TranslationUnit.getMessage(for: .DATE_CUSTOM_TITLE) ?? "Create events")
                    }
                    .foregroundStyle(Color.black)
                    .font(.title)
                    
                    Divider()
                    
                    createCustomBox()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
            }
        }
        .onAppear {
            // clean up
            print("DateView: onAppear")
            let eventsToDelete = eventList.events.filter {
                !$0.saved && inPast(date: $0.start)
            }

            for event in eventsToDelete {
                appViewModel.delete(eventObject: event)
                eventList.events.removeAll { $0.id == event.id }
            }
        }
    }
    
    @ViewBuilder
    private func createSuggestedBox(for event: Binding<EventObject>) -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(TranslationUnit.getMessage(for: .DATE_TITLE_TITLE) ?? "Title")")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Spacer()
                
                TextField(
                    "",
                    text: event.title,
                    prompt: Text(TranslationUnit.getMessage(for: .DATE_TITLE_DESCRIPTION) ?? "Name of the event")
                        .foregroundStyle(Color.gray)
                )
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 5).stroke(Color.gray))
                .frame(maxWidth: 200, alignment: .trailing)
                .autocorrectionDisabled()
                .autocapitalization(.sentences)
                .foregroundColor(Color.black)
            }
            .padding(5)
            
            HStack(spacing: 5) {
                Text("\(TranslationUnit.getMessage(for: .DATE_START_TITLE) ?? "Start"):")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Spacer()
                Text(dateToString(event.wrappedValue.start))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .font(.system(size: 18))
                DatePicker("",
                           selection: event.start,
                           displayedComponents: .hourAndMinute
                )
                .foregroundStyle(Color.black)
                .labelsHidden()
                .colorScheme(.light)
            }
            .padding(5)
            
            HStack(spacing: 5) {
                Text("\(TranslationUnit.getMessage(for: .DATE_END_TITLE) ?? "End"):")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Spacer()
                Text(dateToString(event.wrappedValue.end))
                    .foregroundStyle(Color.black)
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                DatePicker("",
                           selection: event.end,
                           displayedComponents: .hourAndMinute
                )
                .foregroundStyle(Color.black)
                .labelsHidden()
                .colorScheme(.light)
            }
            .padding(5)
            
            if let location = event.wrappedValue.location {
                VStack {
                    HStack(spacing: 5) {
                        Text("\(TranslationUnit.getMessage(for: .DATE_LOCATION_TITLE) ?? "Location"):")
                            .foregroundStyle(Color.black)
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                        Spacer()
                        
                        Text("\(location.adress), \(location.city)")
                            .foregroundStyle(Color.black)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .font(.system(size: 18))
                    }
                    .padding(5)
                    
                    VStack {
                        LocationMapViewContainer(location: location)
                            .cornerRadius(12)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray)
                            )
                    }
                    .padding(5)
                }
            }
            
            HStack(spacing: 5) {
                VStack(alignment: .leading) {
                    Text("\(TranslationUnit.getMessage(for: .DATE_DESCRIPTION_TITLE) ?? "Description"):")
                        .foregroundStyle(Color.black)
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                    TextField(
                        "",
                        text: event.description,
                        prompt: Text(TranslationUnit.getMessage(for: .DATE_DESCRIPTION_DESCRIPTION) ?? "Additional notes")
                            .foregroundStyle(Color.gray)
                    )
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 5).stroke(Color.gray))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.sentences)
                    .foregroundColor(Color.black)
                }
                .padding(5)
            }
            
            // Accept or delete
            HStack {
                Spacer()
                Image(systemName: "plus.square")
                    .foregroundStyle(isSaveable(event: event.wrappedValue) ? Color.green : Color.gray)
                    .font(.system(size: 30))
                    .onTapGesture {
                        pressedSaveButton(with: event.id)
                    }
                Spacer()
                Image(systemName: "minus.square")
                    .foregroundStyle(Color.red)
                    .font(.system(size: 30))
                    .onTapGesture {
                        pressedDeleteButton(with: event)
                    }
                Spacer()
            }
            .padding(5)
        }
    }
    
    private func dateToString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: date)
    }
    
    private func dateToHourString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func pressedDeleteButton(with event: Binding<EventObject>) {
        print("DateView: Pressed delete button \(event.id.uuidString)")
        appViewModel.delete(eventObject: event.wrappedValue)
        eventList.events.removeAll(where: { $0.id == event.id })
    }
    
    private func pressedSaveButton(with eventID: UUID) {
        print("DateView: Pressed save button \(eventID.uuidString)")
        saveEvent(for: eventID) { status in
            if let index = eventList.events.firstIndex(where: { $0.id == eventID }) {
                // need to do it like this otherwise Published wont trigger (references are the same)
                var updatedEvent = eventList.events[index]
                updatedEvent.saved = status
                DispatchQueue.main.async {
                    eventList.events[index] = updatedEvent
                }
                if status {
                    appViewModel.insert(eventObject: updatedEvent, for: eventList.dateObjectID)
                }
            }
        }
    }
    
    // https://medium.com/@thibault.giraudon/how-to-add-events-to-your-calendar-using-swiftui-and-eventkit-9b81528bf397
    
    private func saveEvent(for eventID: UUID, completion: @escaping (Bool) -> Void) {
        eventStore.requestWriteOnlyAccessToEvents() { (granted, error) in
            if let event = eventList.events.first(where: { $0.id == eventID }),
               granted && error == nil, isSaveable(event: event) {
                let calendarEvent = EKEvent(eventStore: eventStore)
                calendarEvent.title = event.title
                calendarEvent.startDate = event.start
                calendarEvent.endDate = event.end
                calendarEvent.notes = event.description
                if let location = event.location {
                    let structuredLocation = EKStructuredLocation(
                        mapItem: MKMapItem(
                            placemark: MKPlacemark(coordinate: location.coordinates))
                    )
                    structuredLocation.title = "\(location.adress), \(location.city)"
                    calendarEvent.structuredLocation = structuredLocation
                }
                calendarEvent.calendar = eventStore.defaultCalendarForNewEvents
                
                do {
                    try eventStore.save(calendarEvent, span: .thisEvent)
                    completion(true)
                } catch {
                    print("DateView: Error saving event.")
                    completion(false)
                }
            } else {
                print("DateView: Not allowed to save event or event is not saveable.")
                completion(false)
            }
        }
    }
    
    private func saveCustomEvent(for event: EventObject, completion: @escaping (Bool) -> Void) {
        print("DateView: Saving custom event starting...")
        eventStore.requestWriteOnlyAccessToEvents() { (granted, error) in
            if granted && error == nil, isSaveable(event: event) {
                let calendarEvent = EKEvent(eventStore: eventStore)
                calendarEvent.title = event.title
                calendarEvent.startDate = event.start
                calendarEvent.endDate = event.end
                calendarEvent.notes = event.description
                if let location = event.location {
                    let structuredLocation = EKStructuredLocation(
                        mapItem: MKMapItem(
                            placemark: MKPlacemark(coordinate: location.coordinates))
                    )
                    structuredLocation.title = "\(location.adress), \(location.city)"
                    calendarEvent.structuredLocation = structuredLocation
                }
                calendarEvent.calendar = eventStore.defaultCalendarForNewEvents
                
                do {
                    try eventStore.save(calendarEvent, span: .thisEvent)
                    completion(true)
                } catch {
                    print("DateView: Error saving custom event.")
                    completion(false)
                }
            } else {
                print("DateView: Not allowed to save custom event or event is not saveable.")
                completion(false)
            }
        }
    }
    
    /**
        This method checks if a given event may be saved or not.
     */
    private func isSaveable(event: EventObject) -> Bool {
        let bool = !event.title.isEmpty && inPast(anchor: event.end, date: event.start) && !inPast(date: event.start) && !event.saved
        print("DateView: isSaveable \(bool)")
        return bool
    }
    
    @ViewBuilder
    private func createSavedBox(for event: Binding<EventObject>) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text("\(TranslationUnit.getMessage(for: .DATE_TITLE_TITLE) ?? "Title"):")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Spacer()
                
                Text(event.wrappedValue.title)
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                    .multilineTextAlignment(.leading)
            }
            .padding(5)
            
            HStack(spacing: 5) {
                Text("\(TranslationUnit.getMessage(for: .DATE_START_TITLE) ?? "Start"):")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Spacer()
                Text(dateToString(event.wrappedValue.start))
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                Text("•")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                Text(dateToHourString(event.wrappedValue.start))
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                
            }
            .padding(5)
            
            HStack(spacing: 5) {
                Text("\(TranslationUnit.getMessage(for: .DATE_START_TITLE) ?? "End"):")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Spacer()
                Text(dateToString(event.wrappedValue.end))
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                Text("•")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                Text(dateToHourString(event.wrappedValue.end))
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                
            }
            .padding(5)
            
            if let location = event.wrappedValue.location {
                VStack {
                    HStack {
                        Text("\(TranslationUnit.getMessage(for: .DATE_LOCATION_TITLE) ?? "Location"):")
                            .foregroundStyle(Color.black)
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                        Spacer()
                        Text("\(location.adress), \(location.city)")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.black)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(5)
                    
                    VStack {
                        LocationMapViewContainer(location: location)
                            .cornerRadius(12)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray)
                            )
                    }
                    .padding(5)
                }
                
            }
            
            if !event.wrappedValue.description.isEmpty {
                VStack(alignment: .leading) {
                    Text("\(TranslationUnit.getMessage(for: .DATE_DESCRIPTION_TITLE) ?? "Description"):")
                        .foregroundStyle(Color.black)
                    Text(event.wrappedValue.description)
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.leading)
                }
            }
            
            // Delete but no accept
            HStack {
                Spacer()
                Image(systemName: "minus.square")
                    .foregroundStyle(Color.red)
                    .font(.system(size: 30))
                    .onTapGesture {
                        pressedDeleteButton(with: event)
                    }
                Spacer()
            }
            .padding(5)
            
        }
    }
    
    /**
        Helper to determine if an event would have already been over (this will only really help for clearing out saved events).
        We need to make sure to check if the date is already past today when creating the DateObject.
     */
    private func inPast(anchor: Date = Date(), date: Date) -> Bool {
        return date < anchor
    }
    
    @ViewBuilder
    private func createCustomBox() -> some View {
        VStack(spacing: 10) {
            HStack {
                Text("\(TranslationUnit.getMessage(for: .DATE_TITLE_TITLE) ?? "Title")")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Spacer()
                
                TextField(
                    "",
                    text: $customTitle,
                    prompt: Text(TranslationUnit.getMessage(for: .DATE_TITLE_DESCRIPTION) ?? "Name of the event")
                        .foregroundStyle(Color.gray)
                )
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 5).stroke(Color.gray))
                .frame(maxWidth: 200, alignment: .trailing)
                .autocorrectionDisabled()
                .autocapitalization(.sentences)
                .foregroundColor(Color.black)
            }
            .padding(5)
            
            HStack(spacing: 5) {
                Text("\(TranslationUnit.getMessage(for: .DATE_START_TITLE) ?? "Start"):")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Spacer()
                DatePicker("",
                           selection: $customStart,
                           displayedComponents: .date
                )
                .foregroundStyle(Color.black)
                .labelsHidden()
                .colorScheme(.light)
                DatePicker("",
                           selection: $customStart,
                           displayedComponents: .hourAndMinute
                )
                .foregroundStyle(Color.black)
                .labelsHidden()
                .colorScheme(.light)
            }
            .padding(5)
            
            HStack(spacing: 5) {
                Text("\(TranslationUnit.getMessage(for: .DATE_END_TITLE) ?? "End"):")
                    .foregroundStyle(Color.black)
                    .font(.system(size: 20))
                    .fontWeight(.bold)
                Spacer()
                DatePicker(
                    "",
                    selection: $customEnd,
                    displayedComponents: .date
                )
                .foregroundStyle(Color.black)
                .labelsHidden()
                .colorScheme(.light)
                DatePicker(
                    "",
                    selection: $customEnd,
                    displayedComponents: .hourAndMinute
                )
                .foregroundStyle(Color.black)
                .labelsHidden()
                .colorScheme(.light)
            }
            .padding(5)
            
            if let location = customLocation {
                // maybe add map beneath it
                VStack(spacing: 5) {
                    HStack(spacing: 5) {
                        Text("\(TranslationUnit.getMessage(for: .DATE_LOCATION_TITLE) ?? "Location"):")
                            .foregroundStyle(Color.black)
                            .font(.system(size: 20))
                            .fontWeight(.bold)
                        Spacer()
                        
                        TextField(
                            "",
                            text: $customAdress,
                            prompt:
                                Text(TranslationUnit.getMessage(for: .DATE_LOCATION_DESCRIPTION) ?? "Adress, City or zip-code")
                                .foregroundStyle(Color.gray)
                        )
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 5).stroke(Color.gray))
                        .frame(maxWidth: 200, alignment: .trailing)
                        .autocorrectionDisabled()
                        .autocapitalization(.sentences)
                        .foregroundColor(Color.black)
                        .onSubmit {
                            if legalAdressDescriptor(), !fetchingLocation {
                                fetchingLocation = true
                                fetchCustomLocation() { location in
                                    if let location = location {
                                        customLocation = location
                                    } else {
                                        customAdress = ""
                                        customLocation = nil
                                    }
                                    fetchingLocation = false
                                }
                            }
                        }
                    }
                    .padding(5)
                    
                    VStack {
                        LocationMapViewContainer(location: location)
                            .cornerRadius(12)
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray)
                            )
                    }
                    .padding(5)
                }
            } else {
                HStack(spacing: 5) {
                    Text("\(TranslationUnit.getMessage(for: .DATE_LOCATION_TITLE) ?? "Location"):")
                        .foregroundStyle(Color.black)
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                    Spacer()
                    
                    TextField(
                        "",
                        text: $customAdress,
                        prompt: Text(TranslationUnit.getMessage(for: .DATE_LOCATION_DESCRIPTION) ?? "Adress, City or zip-code")
                            .foregroundStyle(Color.gray)
                    )
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 5).stroke(Color.gray))
                    .frame(maxWidth: 200, alignment: .trailing)
                    .autocorrectionDisabled()
                    .autocapitalization(.sentences)
                    .foregroundColor(Color.black)
                    .onSubmit {
                        if legalAdressDescriptor(), !fetchingLocation {
                            fetchingLocation = true
                            fetchCustomLocation() { location in
                                if let location = location {
                                    customLocation = location
                                } else {
                                    customAdress = ""
                                    customLocation = nil
                                }
                                fetchingLocation = false
                            }
                        }
                    }
                }
                .padding(5)
            }
            
            HStack(spacing: 5) {
                VStack(alignment: .leading) {
                    Text("\(TranslationUnit.getMessage(for: .DATE_DESCRIPTION_TITLE) ?? "Description"):")
                        .foregroundStyle(Color.black)
                        .font(.system(size: 20))
                        .fontWeight(.bold)
                    TextField(
                        "",
                        text: $customDescription,
                        prompt: Text(TranslationUnit.getMessage(for: .DATE_DESCRIPTION_DESCRIPTION) ?? "Additional notes")
                            .foregroundStyle(Color.gray)
                    )
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 5).stroke(Color.gray))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.sentences)
                    .foregroundColor(Color.black)
                }
                .padding(5)
            }
            
            // Accept but no delete
            HStack {
                Spacer()
                Image(systemName: "plus.square")
                    .foregroundStyle((!isSaving && isCustomEventSaveable()) ? Color.green : Color.gray)
                    .font(.system(size: 30))
                    .onTapGesture {
                        isSaving = true
                        saveCustomEvent()
                    }
                    .disabled(isSaving || !isCustomEventSaveable())
                Spacer()
            }
            .padding(5)
        }
    }
    
    private func isCustomEventSaveable() -> Bool {
        return !customTitle.isEmpty
            && inPast(anchor: customEnd, date: customStart)
            && !inPast(date: customStart)
            && ((customLocation == nil || legalAdressDescriptor()) || customLocation != nil)
            /// if it is empty we are going to fetch location again. Not sure, but I think it is possible that location might not be uptodate,
            /// if the user does not submit the date
    }
    
    /**
        Thanks to past-Lars, present-Lars could use previously implemented method which makes future-Lars happy
     */
    private func fetchCustomLocation(completion: @escaping (Location?) -> Void) {
        print("DateView: Start fetching custom location")
        let wordList = customAdress.wordList
        let zip_codes = wordList.filter({ $0.count == 4 && $0.allSatisfy({ $0.isNumber }) })
        var streets = wordList.filter({ isStreet($0) })
        streets.append(contentsOf: getStreetCandidates(word: customAdress))
        let numbers = wordList.filter { word in word.contains { $0.isNumber } }
        
        // I think not removing words from raw_text is better to not lose spacial information
        // maybe add cities here as well
        let payload = [
            "raw_text": customAdress,
            "preprocessed": [
                "zip_codes": zip_codes,
                "streets": streets,
                "numbers": numbers,
                "cities": []
            ]
        ] as [String : Any]
        print("DateView: \(payload)")
        guard let url = URL(string: "https://myurl.com/location") else {
            print("DateView: URL is nil")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("DateView: Failed to serialize payload")
            completion(nil)
            return
        }
        print("DateView: About to perform request")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                print("DateView: No data returned")
                completion(nil)
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let errorMessage = json?["error"] as? String {
                    print("DateView: Error: \(errorMessage)")
                    completion(nil)
                    return
                }
                print("DateView: Retrieving coordinates")
                if let message = json?["message"] as? String,
                   let x = json?["x"] as? Double,
                   let y = json?["y"] as? Double,
                   let adress = json?["address"] as? String,
                   let city = json?["name"] as? String {
                    print("DateView: \(message) with coordinates \(x), \(y)")
                    let coordinates = CLLocationCoordinate2D(latitude: x, longitude: y)
                    completion(Location(coordinates: coordinates, adress: adress, city: city))
                } else {
                    print("DateView: Missing or invalid data: \(json)")
                    completion(nil)
                }
            } catch {
                print("Error parsing JSON: \(error.localizedDescription)")
                completion(nil)
                return
            }
        }
        .resume()
    }
    
    private func isStreet(_ word: String) -> Bool {
        let streetChunks = ["strasse", "str.", "weg", "platz", "gasse"]
        return streetChunks.contains { chunk in
            word.lowercased().contains(chunk)
        }
    }
    
    private func getStreetCandidates(word: String) -> [String] {
        let wordList = word.wordList
        if wordList.isEmpty { return [] }
        var resultList: Set<String> = []
        for i in 1..<wordList.count {
            let current = wordList[i]
            let previous = wordList[i - 1]
            // Adding strings which are before a string containng a number and itself not containing a number
            // those are potential streets
            if current.contains(where: { $0.isNumber }) && !previous.contains(where: { $0.isNumber }) {
                resultList.insert(previous)
            }
            
            // Mittlere Strasse (Current = Strasse, Previous = Mittlere)
            if isStreet(current)
                && !previous.contains(where: { $0.isNumber })
                && !current.contains(where: { $0.isNumber }) {
                let current = current.lowercased().replacingOccurrences(of: "str.", with: "strasse")
                
                resultList.insert(
                    (previous.appending(current))
                    .lowercased().filter { char in
                        char.isLetter
                    })
            }
        }
        return Array(resultList)
    }
    
    private func saveCustomEvent() {
        print("DateView: Starting to save custom event")
        if customLocation == nil && legalAdressDescriptor() {
            print("DateView: Fetching custom location, eventho user has not requested it.")
            fetchCustomLocation() { location in
                customLocation = location
            }
        }
        
        var customEvent = EventObject(
            title: customTitle,
            start: customStart,
            end: customEnd,
            description: customDescription,
            location: customLocation
        )
        saveCustomEvent(for: customEvent) { status in
            if status {
                // YAY all good
                customEvent.saved = true
                DispatchQueue.main.async {
                    eventList.events.append(customEvent)
                    print("DateView: Custom event saved successfully.")
                }
                customTitle = ""
                customAdress = ""
                customLocation = nil
                customDescription = ""
                customStart = Date().addingTimeInterval(300)
                customEnd = Date().addingTimeInterval(2100)
                appViewModel.insert(eventObject: customEvent, for: eventList.dateObjectID)
            } else {
                // No bueno
                print("DateView: Failed to save custom event.")
            }
            isSaving = false
        }
    }
    
    private func legalAdressDescriptor() -> Bool {
        return !customAdress.isEmpty && !customAdress.trimmingCharacters(in: .whitespaces).isEmpty && customAdress.count < 40
    }
}
