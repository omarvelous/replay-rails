import type { Meta, StoryObj } from "@storybook/react-vite"
import { IdleScreen } from "."

const meta = {
  title: "Player/IdleScreen",
  component: IdleScreen,
  parameters: {
    layout: "fullscreen",
    backgrounds: { default: "dark" },
  },
} satisfies Meta<typeof IdleScreen>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {}
