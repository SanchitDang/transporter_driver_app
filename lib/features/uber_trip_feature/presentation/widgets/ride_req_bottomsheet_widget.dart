import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:get/get.dart';
import 'package:transporter_driver_app/core/widgets/loading_widget.dart';
import 'package:transporter_driver_app/core/widgets/no_internet_widget.dart';
import 'package:transporter_driver_app/features/uber_trip_feature/presentation/cubit/available_for_ride/user_req_cubit.dart';
import 'package:transporter_driver_app/features/uber_trip_feature/presentation/cubit/driver_live_location/driver_location_cubit.dart';
import 'package:transporter_driver_app/features/uber_trip_feature/presentation/cubit/uber_driver_map/uber_map_cubit.dart';
import 'package:transporter_driver_app/features/uber_trip_feature/presentation/pages/goods_details.dart';
import 'package:transporter_driver_app/features/uber_trip_feature/presentation/widgets/custom_elevated_button.dart';

import '../pages/details_controller.dart';
import 'WarehouseDialog.dart';

void rideRequestBottomSheet(BuildContext context) {
  showModalBottomSheet(
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      context: context,
      builder: (builder) {
        BlocProvider.of<UserReqCubit>(context).getUserReq();
        final cubit = BlocProvider.of<UserReqCubit>(context);
        return BlocProvider.value(
            value: cubit,
            child: BlocProvider.value(
                value: BlocProvider.of<UberMapCubit>(context),
                child: BlocProvider.value(
                  value: BlocProvider.of<DriverLocationCubit>(context),
                  child: BlocBuilder<UserReqCubit, UserReqState>(
                    builder: (context, state) {
                      if (state is UserReqInitial) {
                        return const NoInternetWidget(
                            message: "No requests available");
                      } else if (state is UserReqLoading) {
                        return const LoadingWidget();
                      } else if (state is UserReqLoaded) {
                        return Container(
                          height: MediaQuery.of(context).size.height / 2,
                          margin: const EdgeInsets.only(top: 16),
                          child: state.tripHistoryList.isEmpty == true
                              ? const NoInternetWidget(
                                  message: 'No request available',
                                )
                              : ListView.builder(
                                  itemCount: state.tripHistoryList.length,
                                  shrinkWrap: true,
                                  scrollDirection: Axis.vertical,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      title: Text(
                                        state.tripHistoryList[index].riderModel
                                            .name
                                            .toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'source: ${state.tripHistoryList[index].tripHistoryModel.source}',
                                              overflow: TextOverflow.ellipsis),
                                          Text(
                                              'destination: ${state.tripHistoryList[index].tripHistoryModel.destination}',
                                              overflow: TextOverflow.ellipsis),
                                          Text(
                                              'travelling time: ${state.tripHistoryList[index].tripHistoryModel.travellingTime}',
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                      leading: Text(
                                        '${state.tripHistoryList[index].tripHistoryModel.tripAmount} \u{20B9}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      trailing: CustomElevatedButton(
                                        onPressed: () async {
                                          await BlocProvider.of<UserReqCubit>(
                                                  context)
                                              .isAccept(
                                                  state.tripHistoryList[index],
                                                  true,
                                                  false);
                                        },
                                        text: 'ACCEPT',
                                      ),
                                    );
                                  }),
                        );
                      } else if (state is UserReqFailureState) {
                        return NoInternetWidget(
                          message: state.message,
                        );
                      } else if (state is UserReqDisplayOne) {
                        // draw route of ride from driver's current location
                        BlocProvider.of<UberMapCubit>(context)
                            .drawRoute(state, context);

                        return Container(
                          height: MediaQuery.of(context).size.height / 4,
                          margin: const EdgeInsets.only(top: 16),
                          child: ListTile(
                              title: Row(
                                children: [
                                  const Icon(Icons.person_pin),
                                  Text(' ${state.tripDriver.riderModel.name}')
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.my_location),
                                      Text(
                                          ' ${state.tripDriver.tripHistoryModel.source}')
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_sharp),
                                      Text(
                                          ' ${state.tripDriver.tripHistoryModel.destination}')
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.watch_later_outlined),
                                      Text(
                                          ' ${state.tripDriver.tripHistoryModel.travellingTime}')
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.shopping_bag_outlined),
                                      Text(
                                          ' ${state.tripDriver.tripHistoryModel.number_of_goods}')
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      CustomElevatedButton(
                                        onPressed: () {
                                          print('G O O D S  I N F O ----------------->');
                                          print(state.tripDriver.tripHistoryModel.goods_info);
                                          final c = Get.put(DetailsController());
                                          c.addGoodsFromList(state.tripDriver.tripHistoryModel.goods_info);
                                          Get.to(const GoodsDetailsPage());
                                        },
                                        text: 'Show Products',
                                      ),
                                      SizedBox(width:10),
                                      CustomElevatedButton(
                                        onPressed: () {
                                          if (state.tripDriver.tripHistoryModel
                                                  .isCompleted == false) {
                                            //fetch all trips assigned to driver
                                            BlocProvider.of<UserReqCubit>(context)
                                                .isAccept(
                                                    state.tripDriver, false, false);
                                          } else if (state
                                                      .tripDriver
                                                      .tripHistoryModel
                                                      .isCompleted == true
                                              &&
                                              state.tripDriver.tripHistoryModel
                                                      .isArrived == true) {
                                            //when arrived completed trip reset for new ride
                                            BlocProvider.of<UberMapCubit>(context)
                                                .resetMapForNewRide(context);

                                            //display new ride list
                                            BlocProvider.of<UserReqCubit>(context)
                                                .readyForNextRide(false);
                                          } else {
                                            //fetch continuous trips while one trip is accepted
                                            BlocProvider.of<UserReqCubit>(context)
                                                .isAccept(
                                                    state.tripDriver, false, false);
                                          }

                                          // dialog box to send to nearest warehouse
                                          if(state.tripDriver.tripHistoryModel.is_from_admin == true && state.tripDriver.tripHistoryModel
                                              .isCompleted == true ) {
                                            // if trip is set from admin, then
                                            // send to destination user
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return WarehouseDialog(
                                                  latitude: state.tripDriver
                                                      .tripHistoryModel
                                                      .destinationLocation
                                                      ?.latitude ?? 40.7128,
                                                  longitude: state.tripDriver
                                                      .tripHistoryModel
                                                      .destinationLocation
                                                      ?.longitude ??
                                                      -74.0060, // Example longitude
                                                );
                                              },
                                            );
                                          }
                                          else if (true && state.tripDriver.tripHistoryModel
                                              .isCompleted == true){
                                            // send to nearest warehouse
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return WarehouseDialog(
                                                  latitude: state.tripDriver
                                                      .tripHistoryModel
                                                      .warehouseSourceLocation
                                                      ?.latitude ?? 40.7128,
                                                  longitude: state.tripDriver
                                                      .tripHistoryModel
                                                      .warehouseSourceLocation
                                                      ?.longitude ??
                                                      -74.0060, // Example longitude
                                                );
                                              },
                                            );
                                          }

                                        },
                                        text: state.tripDriver.tripHistoryModel
                                                    .isArrived == false
                                            ? 'ARRIVED'
                                            : state.tripDriver.tripHistoryModel
                                                        .isCompleted == true
                                            && state.tripDriver.tripHistoryModel
                                            .is_cod == true
                                                ? 'ACCEPT PAYMENT'
                                                : 'COMPLETED',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              leading: Text(
                                '${state.tripDriver.tripHistoryModel.tripAmount} \u{20B9}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              trailing: GestureDetector(
                                onTap: () async {
                                  String? number =
                                      state.tripDriver.riderModel.mobile;
                                  await FlutterPhoneDirectCaller.callNumber(
                                      number!);
                                },
                                child: const CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  child: Icon(Icons.call),
                                ),
                              )),
                        );
                      }
                      return const NoInternetWidget(
                        message: 'No requests yet.',
                      );
                    },
                  ),
                )));
      });
}
