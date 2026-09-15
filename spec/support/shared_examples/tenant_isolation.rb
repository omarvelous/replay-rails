RSpec.shared_examples "tenant isolated resource" do |factory, path_helper|
  describe "tenant isolation" do
    it "returns 404 for another account's record" do
      other_record = create(factory)
      get send(path_helper, other_record)
      expect(response).to have_http_status(:not_found)
    end
  end
end
