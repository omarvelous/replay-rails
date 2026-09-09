export const EVENTS = {
  "content.impressed": {
    properties: {
      ad_id:             { required: true },
      screen_id:         { required: true },
      screen_content_id: { required: true },
      playlist_id:       { required: true },
      position:          { required: true },
      duration:          { required: true },
    }
  },
  "content.loaded": {
    properties: {
      screen_id:         { required: true },
      screen_content_id: { required: true },
      content_type:      { required: true },
      content_id:        { required: true },
    }
  },
  "interaction.started": {
    properties: {
      experience_id:     { required: true },
      screen_id:         { required: true },
      screen_content_id: { required: true },
    }
  },
  "interaction.ended": {
    properties: {
      experience_id:     { required: true },
      screen_id:         { required: true },
      screen_content_id: { required: true },
      duration:          { required: true },
    }
  },
  "interaction.navigated": {
    properties: {
      experience_id:     { required: true },
      screen_content_id: { required: true },
      direction:         { required: true },
      photo_index:       { required: true },
    }
  },
  "interaction.opened": {
    properties: {
      experience_id:     { required: true },
      screen_content_id: { required: true },
      target:            { required: true },
    }
  },
  "interaction.closed": {
    properties: {
      experience_id:     { required: true },
      screen_content_id: { required: true },
      target:            { required: true },
      view_duration:     { required: true },
    }
  },
  "device.connected": {
    properties: {
      screen_id:    { required: true },
      player_token: { required: true },
    }
  }
}
