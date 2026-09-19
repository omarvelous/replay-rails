export const EVENTS = {
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
  "interaction.started": {
    properties: {
      experience_pid:     { required: true },
      screen_pid:         { required: true },
      screen_content_pid: { required: true },
      account_pid:        { required: true },
    }
  },
  "interaction.ended": {
    properties: {
      experience_pid:     { required: true },
      screen_pid:         { required: true },
      screen_content_pid: { required: true },
      account_pid:        { required: true },
      duration:           { required: true },
    }
  },
  "interaction.navigated": {
    properties: {
      experience_pid:     { required: true },
      screen_content_pid: { required: true },
      account_pid:        { required: true },
      direction:          { required: true },
      photo_index:        { required: true },
    }
  },
  "interaction.opened": {
    properties: {
      experience_pid:     { required: true },
      screen_content_pid: { required: true },
      account_pid:        { required: true },
      target:             { required: true },
    }
  },
  "interaction.closed": {
    properties: {
      experience_pid:     { required: true },
      screen_content_pid: { required: true },
      account_pid:        { required: true },
      target:             { required: true },
      view_duration:      { required: true },
    }
  },
  "device.connected": {
    properties: {
      screen_pid:    { required: true },
      player_pid:    { required: true },
      account_pid:   { required: true },
    }
  }
}
