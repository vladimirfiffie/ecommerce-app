import 'package:ecommerce_app/data/models/address.dart';
import 'package:ecommerce_app/data/models/category.dart';
import 'package:ecommerce_app/data/models/delivery_option.dart';
import 'package:ecommerce_app/data/models/drop_off.dart';
import 'package:ecommerce_app/data/models/order.dart';
import 'package:ecommerce_app/data/models/order_line.dart';
import 'package:ecommerce_app/data/models/product.dart';
import 'package:ecommerce_app/data/repositories/product_repository.dart';
import 'package:ecommerce_app/state/app_providers.dart';
import 'package:ecommerce_app/state/cart_provider.dart';
import 'package:ecommerce_app/state/delivery_instructions_provider.dart';
import 'package:ecommerce_app/state/orders_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  final Product mug = testProduct(id: 'mug', name: 'Mug', price: 10);
  final Catalog catalog = Catalog(
    categories: <Category>[],
    products: <Product>[mug],
  );

  const Address here = Address(
    id: 'a1',
    label: 'Home',
    recipient: 'Ada',
    line1: '1 Test Way',
    city: 'Springfield',
    postcode: '62704',
    country: 'United States',
  );

  Future<ProviderContainer> ready({
    Map<String, Object> initialPrefs = const <String, Object>{},
  }) async {
    final ProviderContainer c = await testContainer(
      catalog: catalog,
      initialPrefs: initialPrefs,
    );
    await c.read(catalogProvider.future);
    await c.read(cartProvider.notifier).add(mug);
    return c;
  }

  Future<Order> place(
    ProviderContainer c, {
    DeliveryOption delivery = DeliveryOption.standard,
  }) => c
      .read(ordersProvider.notifier)
      .placeOrder(
        address: here,
        paymentLabel: 'Visa ····4242',
        delivery: delivery,
      );

  test('the default asks for nothing and says nothing', () async {
    final ProviderContainer c = await ready();
    expect(c.read(deliveryInstructionsProvider).isDefault, isTrue);

    final Order order = await place(c);
    expect(order.hasDeliveryInstructions, isFalse);
    // Nothing worth writing down means nothing written down.
    expect(order.toJson().containsKey('dropOffId'), isFalse);
    expect(order.toJson().containsKey('deliveryNote'), isFalse);
  });

  test('a choice and a note reach the order', () async {
    final ProviderContainer c = await ready();
    await c
        .read(deliveryInstructionsProvider.notifier)
        .setDropOff(DropOff.safePlace);
    await c
        .read(deliveryInstructionsProvider.notifier)
        .setNote('  Gate code 1234  ');

    final Order order = await place(c);
    expect(order.dropOff, DropOff.safePlace);
    expect(order.deliveryNote, 'Gate code 1234');
    expect(order.hasDeliveryInstructions, isTrue);
  });

  test('pickup has no doorstep, so it carries no instruction', () async {
    // An instruction about a door there isn't is a promise to nobody.
    final ProviderContainer c = await ready();
    await c
        .read(deliveryInstructionsProvider.notifier)
        .setDropOff(DropOff.atDoor);
    await c.read(deliveryInstructionsProvider.notifier).setNote('Round back');

    final Order order = await place(c, delivery: DeliveryOption.pickup);
    expect(order.dropOff, DropOff.handToMe);
    expect(order.deliveryNote, isEmpty);
    expect(order.hasDeliveryInstructions, isFalse);
    expect(DropOff.appliesTo(DeliveryOption.pickup.id), isFalse);
  });

  test('it is remembered for the next order', () async {
    // Where to leave a parcel is about the door, not about one order — a
    // shopper with a porch on Tuesday still has one on Friday.
    final ProviderContainer c = await ready();
    await c
        .read(deliveryInstructionsProvider.notifier)
        .setDropOff(DropOff.withNeighbour);
    await c.read(deliveryInstructionsProvider.notifier).setNote('Number 12');
    await place(c);

    expect(c.read(deliveryInstructionsProvider).dropOff, DropOff.withNeighbour);
    expect(c.read(deliveryInstructionsProvider).note, 'Number 12');
  });

  test('a note longer than a label is cut to fit', () async {
    final ProviderContainer c = await ready();
    await c
        .read(deliveryInstructionsProvider.notifier)
        .setNote('x' * (DropOff.maxNoteLength + 40));
    expect(
      c.read(deliveryInstructionsProvider).note.length,
      DropOff.maxNoteLength,
    );
  });

  test('an order survives a round trip through storage', () async {
    final ProviderContainer c = await ready();
    await c
        .read(deliveryInstructionsProvider.notifier)
        .setDropOff(DropOff.atDoor);
    await c.read(deliveryInstructionsProvider.notifier).setNote('Blue door');
    final Order order = await place(c);

    final Order back = Order.fromJson(order.toJson());
    expect(back.dropOff, DropOff.atDoor);
    expect(back.deliveryNote, 'Blue door');
  });

  test('an order written before this existed still loads', () async {
    final Order old = Order(
      id: 'NV-OLD',
      placedAt: DateTime(2026, 1, 1),
      lines: const <OrderLine>[],
      subtotal: 10,
      shipping: 0,
      discount: 0,
      total: 10.8,
      shippingAddress: 'Ada, 1 Test Way',
      paymentLabel: 'Visa ····4242',
    );
    final Order back = Order.fromJson(old.toJson());
    expect(back.dropOff, DropOff.handToMe);
    expect(back.hasDeliveryInstructions, isFalse);
  });
}
