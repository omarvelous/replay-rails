import type { Meta, StoryObj } from "@storybook/react-vite"
import { SplitLandscape } from "."
import { AdCanvas } from "../../AdCanvas"
import { mockPlaylistAd, mockListingAd, mockListing, mockAttachment } from "../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../types"

function Wrap(props: React.ComponentProps<typeof SplitLandscape> & { theme?: string }) {
  return (
    <div style={{ width: 960, height: 540 }}>
      <AdCanvas theme={props.theme ?? "dark"} aspect="landscape">
        <SplitLandscape {...props} />
      </AdCanvas>
    </div>
  )
}

const meta = {
  title: "Ads/Split/Landscape",
  component: SplitLandscape,
  render: (args) => <Wrap {...args} />,
  parameters: { layout: "centered", backgrounds: { default: "dark" } },
} satisfies Meta<typeof SplitLandscape>

export default meta
type Story = StoryObj<typeof meta>

const ad = mockPlaylistAd({
  layout: "split",
  images: [mockAttachment({ url: "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1920&h=1080&fit=crop" })],
})

export const Default: Story = {
  args: { ad, listingAd: ad.adable as ManifestListingAd },
}

export const PriceReduction: Story = {
  args: {
    ad: mockPlaylistAd({ layout: "split", images: ad.images }),
    listingAd: mockListingAd({
      badge: "price_reduction", badge_label: "Price Reduced",
      original_price: 2800000,
      listing: mockListing({ price: 2500000 }),
    }),
  },
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

export const LightTheme: Story = {
  args: { ad, listingAd: ad.adable as ManifestListingAd } as any,
  render: (args: any) => <Wrap {...args} theme="light" />,
}
