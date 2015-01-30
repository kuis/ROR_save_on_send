(function($){
	var self = window.form = {
		
		data : {
			country : 0,
			amount_type : "send"
		},
		
		init : function() {

			// Date picker
			var d = new Date(),
				minDate = (d.getMonth() + 1) + "/" + (d.getDate() + 1) + "/" + (d.getFullYear() - 1),
				maxDate = (d.getMonth() + 1) + "/" + d.getDate() + "/" + d.getFullYear();
		
			$('.input-group.date').datetimepicker({
			    minDate: minDate,
			    maxDate: maxDate,
			    showToday: true,
			    pickTime: false
			});


			// Set initial values
			self.data.country = ($.cookie("money_transfer_destination_id")) ? $.cookie("money_transfer_destination_id") : $('[name="user_next_transfer[money_transfer_destination_id]"]:checked').val();
			self.data.amount_type = $('[name="amount_type"]:checked').data('toggle-amount');
	    	self.show_hide_receive_currency();
			

		    $('[name="user_next_transfer[receive_currency]"]').click(function() {
		    	$('#amount_receive_currency').html($('<i class="fa fa-fw fa-'+$(this).val().toLowerCase()+'">'));
		    });
		
		
		    $('[href="#apply_payment_methods"]').click(function() {
				$('#user_next_transfer_originating_source_of_funds_id_' + $('.send_method_id', $(this).parent()).text()).attr('checked', true);
				$('#user_next_transfer_destination_preference_for_funds_id_' + $('.receive_method_id', $(this).parent()).text()).attr('checked', true);
				$('form.user_next_transfer').submit();
		    });
		
		
		    $('[name="amount_type"]').change(function() {
		    	self.amount_type_change(this);
		    	self.show_hide_receive_currency();
		    });		


		    $('[name="user_next_transfer[money_transfer_destination_id]"]').change(function() {
		    	self.distination_change(this);
		    	self.show_hide_receive_currency();
		    });
		},
		
		// Show or hide receive currency
		show_hide_receive_currency : function() {
			if (self.data.amount_type == 'receive') {
				$('.receive_currency').addClass('hidden');
				$('#receive_currency_' + self.data.country).removeClass('hidden');	
			}
			else {
				$('.receive_currency').addClass('hidden');
			}			
		},
		
		// Change distination
		distination_change : function(el) {
			self.data.country = $(el).val();
			  
			$('#amount_receive_currency').html('');
			
			if (self.data.country == 2) {
				$('#amount_receive_currency').html($('<i class="fa fa-fw fa-inr">'));	  	
			}
			if (self.data.country == 3) {
				$('#amount_receive_currency').html($('<i class="fa fa-fw fa-mxn">'));	  	
			}
		},

		// Change amount type
		amount_type_change : function(el) {
			self.data.amount_type = $(el).data('toggle-amount');
		}
	};

    // Onload
    $(self.init);

})(jQuery);