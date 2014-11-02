FactoryGirl.define do
  factory :user do
    first_name  { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    email { Faker::Internet.email }
    
    zipcode { Faker::Address.zip_code }

    money_transfer_destination { Country.first }
    
    password "password123"
    password_confirmation {|user| user.password}
  end
end
