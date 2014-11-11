class UserNextTransfersController < ApplicationController
  before_filter :authenticate_user!

  def new
    @user_next_transfer = User::NextTransfer.new(params[:user_next_transfer])
  end

  def show
    @user_next_transfer = User::NextTransfer.find(params[:id])
    
    destination_country = current_user.money_transfer_destination

    @least_expensive_remittance_terms = RemittanceTerm.least_expensive(
        amount_send: @user_next_transfer.amount_send, 
        receive_country: destination_country,
        receive_currency: @user_next_transfer.receive_currency,
        send_method: @user_next_transfer.originating_source_of_funds,
        receive_method: @user_next_transfer.destination_preference_for_funds
    )
  end

  def create
    next_transfer_attrs = params.require(:user_next_transfer)
      .permit(:amount_send, :amount_receive, :receive_currency, 
              :originating_source_of_funds_id, :destination_preference_for_funds_id)

    @user_next_transfer = current_user.next_transfers.create(next_transfer_attrs)

    if @user_next_transfer.persisted?
      redirect_to(user_next_transfer_path(@user_next_transfer))
    else
      render :new
    end
  end
end
