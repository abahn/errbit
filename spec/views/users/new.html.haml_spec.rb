require 'spec_helper'

describe 'users/new.html.haml', :type => :view do
  let(:user) { stub_model(User) }
  before {
    allow(view).to receive(:current_user).and_return(user)
    assign :user, user
  }
  it 'should have per_page option' do
    render
    expect(rendered).to match(/id="user_per_page"/)
  end

  it 'should have time_zone option' do
    render
    expect(rendered).to match(/id="user_time_zone"/)
  end
end
