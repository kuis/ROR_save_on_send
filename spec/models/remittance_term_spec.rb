require 'spec_helper'

describe RemittanceTerm do
  let!(:mexico){FactoryGirl.create(:mexico)}
  let(:remittance_term){FactoryGirl.create(:remittance_term, :western_union_mexico)}

  before do
    # stub csv data
    data =
      %Q{Send country,Receive country,Remit name,Sending type,Receiving type,Send currency,To which currency?,Send amount range ($USD) - From,Send amount range ($USD) - To,Fees for sending - USD,Fees for sending - %,FX markup,Receiving fee (in Column D currency),Receiving fee (%),Send-to-receive - Duration (hours),Documentation requirements,Promotions,Service quality,Comments\n} +
      %Q{USA,Mexico,Western Union,bank,cash,USD,MXN,100,"2,999",4,,2.49,,,120,,,\n} +
      %Q{USA,Mexico,Western Union,cash,bank,USD,MXN,0,99,4,,2.49,,,72,,,\n} +
      %Q{USA,Mexico,Western Union,cash,cash,USD,MXN,0,99,5,,2.49,,,1,,,\n} +
      %Q{USA,Mexico,Xoom,bank,"cash, bank",USD,MXN,25,"2,999",4.99,,2.88,,,0,,,}
    
    csv_file = Rails.root.join('db/seeds', 'remittance_terms.csv')
    allow(File).to receive(:open).and_call_original
    allow(File).to receive(:open).with(csv_file, universal_newline: false, headers: :first_row) {StringIO.new(data)}
 
    FactoryGirl.create(:service_provider, :western_union)
    FactoryGirl.create(:service_provider, :xoom)
  
    FactoryGirl.create(:payment_method, :bank)
    FactoryGirl.create(:payment_method, :cash)
  end

  describe '#send_amount_with_fee' do 
    it 'should return send amount with sending fee' do
      expect(
        remittance_term.send_amount_with_fee(Money.new(10000, 'USD'))
      ).to eq(104)
    end
  end

  describe '#all_fees' do
    it 'should return all the fees' do
      expect(
        remittance_term.all_fees(Money.new(100000, 'USD'))
      ).to eq(2.83)
    end
  end

  describe '#estimated_receive_amount' do
    it 'should return amount that user will receive in indian rupee' do
      expect(
        remittance_term.estimated_receive_amount(Money.new(10000, 'USD'), 'INR')
      ).to eq(Money.new(617489, 'INR'))
    end

    it 'should return amount that user will receive in usd' do
      expect(
        remittance_term.estimated_receive_amount(Money.new(10000, 'USD'), 'USD')
      ).to eq(Money.new(9757, 'USD'))
    end
  end

  describe '.least_expensive' do
    before do
      RemittanceTerm.import_from_csv
    end

    it 'should retun least experience remmittance' do
      least_expensive = RemittanceTerm.least_expensive(amount_send: Money.new(5000, 'USD'), 
                                                       receive_country: mexico, 
                                                       receive_currency: 'MXN').first

      expect(least_expensive.send_method.slug).to eq('cash')
      expect(least_expensive.receive_method.slug).to eq('bank')
      expect(least_expensive.service_provider.name).to eq('Western Union')
      expect(least_expensive.expense).to eq(10.49)
    end
  end

  describe '.save_on_transaction' do
    before do
      RemittanceTerm.import_from_csv
    end

    it 'should return amount which user can save on transaction' do
      user = FactoryGirl.create(:user, money_transfer_destination: mexico)
      transaction = FactoryGirl.create(:recent_transaction, user: user, 
                                       amount_sent: 50, amount_received: 640,
                                       currency: 'MXN')

      amount_save = RemittanceTerm.save_on_transaction(transaction)

      expect(amount_save).to eq(Money.new(5092, 'MXN'))
    end

    it 'should return $1 for USD - USD transaction to China' do
      china = FactoryGirl.create(:china)
      FactoryGirl.create(:remittance_term, :ria_china, receive_country: china)

      user = FactoryGirl.create(:user, money_transfer_destination: china)

      recent_transaction = FactoryGirl.create(
        :recent_transaction, 
        user: user,
        amount_sent: 84, 
        amount_received: 83, 
        fees_for_sending: 3,
        currency: 'USD'
      )

      amount_save = RemittanceTerm.save_on_transaction(recent_transaction)

      expect(amount_save).to eq(1)
    end
  end

  describe '.import_from_csv' do 
    it 'should import 5 records from csv to db' do
      expect{
        RemittanceTerm.import_from_csv
      }.to change(RemittanceTerm, :count).by(5)
    end

    it 'should import all the fields from csv' do
      RemittanceTerm.import_from_csv

      remittance_term = RemittanceTerm.first

      expect(remittance_term.receive_country.name).to eq('Mexico')
      expect(remittance_term.service_provider.name).to eq('Western Union')
      expect(remittance_term.send_method.name).to eq('bank account')
      expect(remittance_term.receive_method.name).to eq('cash')
      expect(remittance_term.receive_currency).to eq('MXN')
      expect(remittance_term.send_amount_range_from).to eq(100)
      expect(remittance_term.send_amount_range_to).to eq(2999)
      expect(remittance_term.fees_for_sending.to_i).to eq(4)
      expect(remittance_term.fees_for_sending_percent).to eq(0)
      expect(remittance_term.fx_markup).to eq(2.49)
      expect(remittance_term.duration).to eq('120')
      expect(remittance_term.documentation).to be_nil
      expect(remittance_term.promotions).to be_nil
      expect(remittance_term.service_quality).to be_nil
    end
  end
end
