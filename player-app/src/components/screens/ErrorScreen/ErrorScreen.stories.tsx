import type { Meta, StoryObj } from "@storybook/react-vite"
import { ErrorScreen } from "."

const meta = {
  title: "Player/ErrorScreen",
  component: ErrorScreen,
  parameters: {
    layout: "fullscreen",
    backgrounds: { default: "dark" },
  },
} satisfies Meta<typeof ErrorScreen>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  args: {
    error: "Network connection lost",
  },
}

export const ApiError: Story = {
  args: {
    error: "Failed to load content (503 Service Unavailable)",
  },
}
