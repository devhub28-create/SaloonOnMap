import 'package:api_client/api_client.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/admin_error_message.dart';

abstract class AdminOffersState {}

class AdminOffersInitial extends AdminOffersState {}

class AdminOffersLoading extends AdminOffersState {}

class AdminOffersLoaded extends AdminOffersState {
  final List<Map<String, dynamic>> offers;

  AdminOffersLoaded(this.offers);
}

class AdminOffersError extends AdminOffersState {
  final String message;

  AdminOffersError(this.message);
}

class AdminOffersCubit extends Cubit<AdminOffersState> {
  final ApiClient apiClient;

  AdminOffersCubit({required this.apiClient}) : super(AdminOffersInitial());

  Future<void> fetchOffers() async {
    emit(AdminOffersLoading());
    try {
      final offers = await apiClient.getAdminOffers();
      emit(AdminOffersLoaded(offers
          .map((offer) => Map<String, dynamic>.from(offer as Map))
          .toList()));
    } catch (error) {
      emit(AdminOffersError(
          adminErrorMessage(error, fallback: 'Offers could not be loaded.')));
    }
  }

  Future<bool> createOffer(Map<String, dynamic> data) async {
    try {
      await apiClient.createAdminOffer(data);
      await fetchOffers();
      return true;
    } catch (error) {
      emit(AdminOffersError(adminErrorMessage(error,
          fallback: 'The offer could not be created.')));
      return false;
    }
  }

  Future<bool> setActive(String offerId, bool isActive) async {
    try {
      await apiClient.updateAdminOfferStatus(offerId, isActive);
      await fetchOffers();
      return true;
    } catch (error) {
      emit(AdminOffersError(adminErrorMessage(error,
          fallback: 'The offer could not be updated.')));
      return false;
    }
  }
}
