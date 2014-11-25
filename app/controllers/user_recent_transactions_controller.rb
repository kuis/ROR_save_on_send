class UserRecentTransactionsController < ApplicationController
  before_filter :authenticate_user!

  def new
    @user_recent_transaction = User::RecentTransaction.new(params[:user_recent_transaction])
  end

  def create
    params[:user_recent_transaction][:documentation_requirements] = params[:user_recent_transaction][:documentation_requirements].join(',')

    recent_transaction_attrs = params.require(:user_recent_transaction)
      .permit(:date, :currency, :amount_sent, :amount_received, :originating_source_of_funds_id,
              :service_provider_id, :destination_preference_for_funds_id, :fees_for_sending,
              :fees_for_receiving, :send_to_receive_duration, :send_to_receive_duration_interval,
              :documentation_requirements, :promotion, :service_quality, :comments)

    @user_recent_transaction = current_user.recent_transactions.create(recent_transaction_attrs)

    if @user_recent_transaction.persisted?
      notice = "Congratulations! Your recent transfer used the best approach!"

      more_money = RemittanceTerm.save_on_transaction(@user_recent_transaction)

      if more_money > 0
        destination_country = current_user.money_transfer_destination.name

        notice = "On your last transaction, your recipient in " +
          "#{destination_country} could have received " +
          "#{more_money} more #{more_money.currency.iso_code}"
      end

      redirect_to(new_user_next_transfer_path, notice: notice)
    else
      render :new
    end
  end

  private
end
