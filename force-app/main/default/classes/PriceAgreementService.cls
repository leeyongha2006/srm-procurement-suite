/**
 * 계약이 최종 서명되면 새 단가를 만들고, 같은 품목 · 공급사의 기존 단가 중
 * 기간이 겹치는 것을 정리한다.
 *
 * 겹치는 단가를 그대로 두면 발주 시점에 단가가 두 개 잡힌다.
 *  - 새 단가보다 먼저 시작한 단가: 새 단가 시작 전날로 종료일을 당긴다.
 *  - 새 단가 시작일 이후에 시작하는 단가: 쓰일 일이 없으므로 비활성으로 바꾼다.
 */
public with sharing class PriceAgreementService {

    public class PriceLine {
        public String itemCode;
        public String supplierCode;
        public Decimal unitPrice;
        public Date startDate;
        public Date endDate;     // null 이면 종료일 없음
        public Boolean isActive = true;

        public PriceLine(String itemCode, String supplierCode, Decimal unitPrice, Date startDate, Date endDate) {
            this.itemCode = itemCode;
            this.supplierCode = supplierCode;
            this.unitPrice = unitPrice;
            this.startDate = startDate;
            this.endDate = endDate;
        }

        public String key() {
            return itemCode + '|' + supplierCode;
        }

        public Boolean overlaps(PriceLine other) {
            Date thisEnd = endDate == null ? Date.newInstance(9999, 12, 31) : endDate;
            Date otherEnd = other.endDate == null ? Date.newInstance(9999, 12, 31) : other.endDate;
            return startDate <= otherEnd && other.startDate <= thisEnd;
        }
    }

    public class Result {
        public List<PriceLine> created = new List<PriceLine>();
        public List<PriceLine> shortened = new List<PriceLine>();
        public List<PriceLine> deactivated = new List<PriceLine>();
    }

    /**
     * 서명된 계약 여러 건의 단가를 한 번에 처리한다 (품목 · 공급사 키로 묶어 한 번만 순회).
     *
     * @param existing 현재 활성 단가
     * @param incoming 서명된 계약에서 나온 새 단가
     */
    public static Result apply(List<PriceLine> existing, List<PriceLine> incoming) {
        Map<String, List<PriceLine>> existingByKey = new Map<String, List<PriceLine>>();
        for (PriceLine line : existing) {
            if (!line.isActive) {
                continue;
            }
            if (!existingByKey.containsKey(line.key())) {
                existingByKey.put(line.key(), new List<PriceLine>());
            }
            existingByKey.get(line.key()).add(line);
        }

        Result result = new Result();
        for (PriceLine newLine : incoming) {
            List<PriceLine> sameKey = existingByKey.get(newLine.key());
            if (sameKey != null) {
                closeOverlaps(sameKey, newLine, result);
            }
            result.created.add(newLine);
        }
        return result;
    }

    private static void closeOverlaps(List<PriceLine> candidates, PriceLine newLine, Result result) {
        for (PriceLine old : candidates) {
            if (!old.isActive || !old.overlaps(newLine)) {
                continue;
            }
            if (old.startDate < newLine.startDate) {
                old.endDate = newLine.startDate.addDays(-1);
                result.shortened.add(old);
            } else {
                old.isActive = false;
                result.deactivated.add(old);
            }
        }
    }
}
