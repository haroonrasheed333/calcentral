module GoogleApps
  class EventsDelete < Events
    def delete_event(event_id)
      request(api: self.class.api,
              params: {"calendarId" => "primary", "eventId" => "#{event_id}"},
              resource: "events",
              method: "delete",
              body: "",
              headers: {"Content-Type" => "application/json"},
              vcr_id: "_events_delete").first
    end
  end
end