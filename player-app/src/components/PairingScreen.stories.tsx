import type { Meta, StoryObj } from "@storybook/react-vite"
import { PairingScreen } from "./PairingScreen"

const meta = {
  title: "Player/PairingScreen",
  component: PairingScreen,
  parameters: {
    layout: "fullscreen",
    backgrounds: { default: "dark" },
  },
} satisfies Meta<typeof PairingScreen>

export default meta
type Story = StoryObj<typeof meta>

export const Default: Story = {
  args: {
    code: "W8NFOC",
    expiresAt: new Date(Date.now() + 300_000),
    onCodeExpired: () => {},
  },
}

export const ExpiringShortly: Story = {
  args: {
    code: "ABC123",
    expiresAt: new Date(Date.now() + 15_000),
    onCodeExpired: () => {},
  },
}

export const LongCode: Story = {
  args: {
    code: "XY9Z0A",
    expiresAt: new Date(Date.now() + 600_000),
    onCodeExpired: () => {},
  },
}
