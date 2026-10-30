@IsTest
private class PriceAgreementService_Test {

    private static PriceAgreementService.PriceLine line(String item, Decimal price, Date startDate, Date endDate) {
        return new PriceAgreementService.PriceLine(item, 'SUP-A', price, startDate, endDate);
    }

    @IsTest
    static void shortensPriceThatStartedEarlier() {
        PriceAgreementService.PriceLine old = line('ITEM-1', 100, Date.newInstance(2026, 1, 1), null);
        PriceAgreementService.PriceLine signed = line('ITEM-1', 90, Date.newInstance(2026, 7, 1), Date.newInstance(2026, 12, 31));

        PriceAgreementService.Result result = PriceAgreementService.apply(
            new List<PriceAgreementService.PriceLine>{ old },
            new List<PriceAgreementService.PriceLine>{ signed }
        );

        Assert.areEqual(Date.newInstance(2026, 6, 30), old.endDate);
        Assert.areEqual(1, result.shortened.size());
        Assert.areEqual(1, result.created.size());
    }

    @IsTest
    static void deactivatesPriceThatStartsInsideTheNewPeriod() {
        PriceAgreementService.PriceLine future = line('ITEM-1', 110, Date.newInstance(2026, 9, 1), null);
        PriceAgreementService.PriceLine signed = line('ITEM-1', 90, Date.newInstance(2026, 7, 1), null);

        PriceAgreementService.Result result = PriceAgreementService.apply(
            new List<PriceAgreementService.PriceLine>{ future },
            new List<PriceAgreementService.PriceLine>{ signed }
        );

        Assert.isFalse(future.isActive);
        Assert.areEqual(1, result.deactivated.size());
    }

    @IsTest
    static void leavesNonOverlappingAndOtherItemsAlone() {
        PriceAgreementService.PriceLine ended = line('ITEM-1', 100, Date.newInstance(2025, 1, 1), Date.newInstance(2025, 12, 31));
        PriceAgreementService.PriceLine otherItem = line('ITEM-2', 100, Date.newInstance(2026, 1, 1), null);
        PriceAgreementService.PriceLine signed = line('ITEM-1', 90, Date.newInstance(2026, 1, 1), null);

        PriceAgreementService.Result result = PriceAgreementService.apply(
            new List<PriceAgreementService.PriceLine>{ ended, otherItem },
            new List<PriceAgreementService.PriceLine>{ signed }
        );

        Assert.areEqual(Date.newInstance(2025, 12, 31), ended.endDate);
        Assert.isNull(otherItem.endDate);
        Assert.isTrue(result.shortened.isEmpty());
        Assert.isTrue(result.deactivated.isEmpty());
    }

    @IsTest
    static void handlesBulkContracts() {
        List<PriceAgreementService.PriceLine> existing = new List<PriceAgreementService.PriceLine>();
        List<PriceAgreementService.PriceLine> incoming = new List<PriceAgreementService.PriceLine>();
        for (Integer i = 0; i < 200; i++) {
            existing.add(line('ITEM-' + i, 100, Date.newInstance(2026, 1, 1), null));
            incoming.add(line('ITEM-' + i, 95, Date.newInstance(2026, 4, 1), null));
        }

        Test.startTest();
        PriceAgreementService.Result result = PriceAgreementService.apply(existing, incoming);
        Test.stopTest();

        Assert.areEqual(200, result.shortened.size());
        Assert.areEqual(200, result.created.size());
        Assert.areEqual(Date.newInstance(2026, 3, 31), existing[199].endDate);
    }
}
