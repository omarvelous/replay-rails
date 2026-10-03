interface PropertySchema {
  required: boolean
}

interface EventSchema {
  properties: Record<string, PropertySchema>
}

export const EVENTS: Record<string, EventSchema> = {
  "content.impressed": {
    properties: {
      ad_pid:             { required: true },
      screen_pid:         { required: true },
      screen_content_pid: { required: true },
      playlist_pid:       { required: true },
      account_pid:        { required: true },
      position:           { required: true },
      duration:           { required: true },
    }
  },
  "content.loaded": {
    properties: {
      screen_pid:         { required: true },
      screen_content_pid: { required: true },
      account_pid:        { required: true },
      content_type:       { required: true },
      content_pid:        { required: true },
    }
  },
  "device.connected": {
    properties: {
      screen_pid:    { required: true },
      player_pid:    { required: true },
      account_pid:   { required: true },
    }
  },
}
