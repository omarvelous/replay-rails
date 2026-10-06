import type { Meta, StoryObj } from "@storybook/react-vite"
import { OverlayLandscape } from "."
import { AdCanvas } from "../../AdCanvas"
import { mockPlaylistAd, mockListingAd, mockListing, mockAttachment } from "../../../../__mocks__/manifest"
import type { ManifestListingAd } from "../../../../types"

function Wrap(props: React.ComponentProps<typeof OverlayLandscape> & { theme?: string }) {
  return (
    <div style={{ width: "100%", maxWidth: 1200, aspectRatio: "16/9" }}>
      <AdCanvas theme={props.theme ?? "dark"} aspect="landscape">
        <OverlayLandscape {...props} />
      </AdCanvas>
    </div>
  )
}

const meta = {
  title: "Ads/Overlay/Landscape",
  component: OverlayLandscape,
  render: (args) => <Wrap {...args} />,
  parameters: { layout: "centered", backgrounds: { default: "dark" } },
} satisfies Meta<typeof OverlayLandscape>

export default meta
type Story = StoryObj<typeof meta>

const ad = mockPlaylistAd({
  layout: "overlay",
  images: [mockAttachment({ url: "https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=1920&h=1080&fit=crop" })],
})

export const Default: Story = {
  args: { ad, listingAd: ad.adable as ManifestListingAd },
}

export const PriceReduction: Story = {
  args: {
    ad: mockPlaylistAd({ layout: "overlay", images: ad.images }),
    listingAd: mockListingAd({
      badge: "price_reduction", badge_label: "Price Reduced",
      original_price: 2800000,
      listing: mockListing({ price: 2500000 }),
    }),
  },
}

export const JustSold: Story = {
  args: {
    ad: mockPlaylistAd({ layout: "overlay", images: ad.images }),
    listingAd: mockListingAd({
      badge: "just_sold", badge_label: "Just Sold",
      sold_price: 2600000,
    }),
  },
}

export const NoAgent: Story = {
  args: {
    ad,
    listingAd: mockListingAd({ agent: undefined }),
  },
}

export const NoImage: Story = {
  args: {
    ad: mockPlaylistAd({ layout: "overlay", images: [] }),
    listingAd: ad.adable as ManifestListingAd,
  },
}

export const LightTheme: Story = {
  args: { ad, listingAd: ad.adable as ManifestListingAd, theme: "light" } as any,
  render: (args: any) => <Wrap {...args} theme="light" />,
}

export const BrandTheme: Story = {
  args: { ad, listingAd: ad.adable as ManifestListingAd } as any,
  render: (args: any) => <Wrap {...args} theme="brand" />,
}
