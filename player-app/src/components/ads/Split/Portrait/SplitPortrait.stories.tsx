import type { Meta, StoryObj } from "@storybook/react-vite"
import { SplitPortrait } from "."
import { AdCanvas } from "../../AdCanvas"
import { mockPlaylistAd, mockListingAd, mockAttachment } from "../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../types"

function Wrap(props: React.ComponentProps<typeof SplitPortrait> & { theme?: string }) {
  return (
    <div style={{ width: 540, height: 960 }}>
      <AdCanvas theme={props.theme ?? "dark"} aspect="portrait">
        <SplitPortrait {...props} />
      </AdCanvas>
    </div>
  )
}

const meta = {
  title: "Ads/Split/Portrait",
  component: SplitPortrait,
  render: (args) => <Wrap {...args} />,
  parameters: { layout: "centered", backgrounds: { default: "dark" } },
} satisfies Meta<typeof SplitPortrait>

export default meta
type Story = StoryObj<typeof meta>

const ad = mockPlaylistAd({
  layout: "split",
  images: [mockAttachment({ url: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1920&h=1080&fit=crop" })],
})

export const Default: Story = {
  args: { ad, listingAd: ad.adable as ManifestListingAd },
}

export const NoAgent: Story = {
  args: { ad, listingAd: mockListingAd({ agent: undefined }) },
}

export const NoImage: Story = {
  args: {
    ad: mockPlaylistAd({ layout: "split", images: [] }),
    listingAd: ad.adable as ManifestListingAd,
  },
}
