import 'dart:async';
import 'dart:convert';

// import 'package:boltz_dart/http.dart';
// import 'package:boltz_dart/types/swap.dart';
// import 'package:boltz_dart/types/swap_status_response.dart';
import 'package:boltz_dart/src/types/swap.dart';
import 'package:boltz_dart/src/types/swap_status_response.dart';
import 'package:boltz_dart/src/utils/http.dart';
import 'package:test/test.dart';

void main() {
  // test('playground', () async {
  //   String str = 'data: {"status":"transaction.claimed"}';
  //   var jsonMap = jsonDecode(str);
  //   print(jsonMap);
  // });

  test('Version', () async {
    final api = await BoltzApi.newBoltzApi();
    final version = await api.getBackendVersion();

    expect(version, startsWith('3.4.0'));
  }, skip: true);

  test('Get pairs', () async {
    final api = await BoltzApi.newBoltzApi();
    final pairs = await api.getSupportedPairs();
    // print(pairs);

    expect(pairs.length, equals(3));
  });

  test('Get status', () async {
    final api = await BoltzApi.newBoltzApi();
    final status = await api.getSwapStatus('5Nke2TZdZLZ5');

    expect(status, equals(SwapStatus.txnClaimed));
  });

  // TODO: Flows for
  // btc to ln-btc - Success
  //   invoiceSet
  //   mempool
  //   confirmed
  //   invoicePending
  //   invoicePaid
  //   claimed

  // btc to ln-btc - Failure (Not enough inbound liquidity)  / Refund
  //   invoiceSet
  //   mempool
  //   confirmed
  //   invoicePending (Attempt refund 1. before this, 2. after this)
  //   waiting

  // ln-btc to btc
  // l-btc to ln-btc
  //   invoiceSet
  //   mempool
  //   invoicePending
  //   invoicePaid
  //   claimed
  // ln-btc to l-btc
  //
  // Try with sending mismatching amounts
  test('Get status stream', () async {
    final api = await BoltzApi.newBoltzApi();

    // const swapId = 'kuaECCcK4ZJ9'; // #2
    // const swapId = 'TSMILwPf2HCu'; // #3
    // const swapId = 'c9A3aEaQz1Iu'; // #4
    // const swapId = 'dhbn5n2ypzBC'; // #5
    const swapId = 'QbkqhN9ed2zQ'; // #6
    Stream<SwapStatusResponse> eventStream = api.getSwapStatusStream(swapId);

    var receivedEvents = <SwapStatusResponse>[];

    var completer = Completer();

    var subscription = eventStream.listen((event) {
      receivedEvents.add(event);

      // Optionally, you can set a condition to complete the test
      // For example, if a specific event is received
      //if (event == 'specific_event') {
      //  completer.complete();
      //}
    }, onError: (e) {
      completer.completeError(e);
    }, onDone: () {
      completer.complete();
    });

    await completer.future;

    await subscription.cancel();

    print('receivedEvents: $receivedEvents');
    SwapStatusResponse firstEvent = receivedEvents.first;

    expect(firstEvent.status, equals(SwapStatus.txnClaimed));
  }, skip: true, timeout: const Timeout(Duration(minutes: 120)));
}
