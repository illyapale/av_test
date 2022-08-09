/**
 * Created by IlliaLuhovyi on 9/8/2022.
 */

public with sharing class TourService {

    public Integer generateTours(Set<Id> excursionTypeIds, Date startDate, Date endDate) {
        this.validate(excursionTypeIds, startDate, endDate);

        Integer daysBetween = startDate.daysBetween(endDate);
        Integer numberOfTours = 0;
        Tour__c[] tours = new Tour__c[]{};
        ExcursionType__c[] excursionTypes = [
                SELECT
                    DaysOfWeek__c,
                    Name,
                (
                    SELECT Name
                    FROM Tours__r
                )
                FROM ExcursionType__c
                WHERE Id IN :excursionTypeIds
                AND DaysOfWeek__c <> NULL
                LIMIT 50000
        ];
        Set<String> existingTourNames = this.getTourNames(excursionTypes);

        for (Integer i = 0; i <= daysBetween; i++) {
            Date tourDate = startDate.addDays(i);
            Datetime dt = (Datetime) tourDate;
            String dayOfWeek = dt.format('EE');

            for (ExcursionType__c excursionType : excursionTypes) {
                String tourName = excursionType.Name + ' ' + this.formatDate(tourDate);

                if (excursionType.DaysOfWeek__c.contains(dayOfWeek) && !existingTourNames.contains(tourName)) {
                    numberOfTours++;
                    tours.add(new Tour__c(
                            ExcursionType__c = excursionType.Id,
                            Name = tourName,
                            Date__c = tourDate
                    ));
                }
            }
        }

        try {
            insert tours;
        }
        catch (Exception exc) {
            throw new TourServiceException('Records not inserted');
        }

        //NOTE: it can be not right quantity, better to return inserted tours size.
        return numberOfTours;
    }

    private String formatDate(Date thisDate) {
        return thisDate.day() + '.' + thisDate.month() + '.' + thisDate.year();
    }

    private Set<String> getTourNames(ExcursionType__c[] excursionTypes) {
        Set<String> names = new Set<String>();

        for (ExcursionType__c excursionType: excursionTypes) {

            for (Tour__c tour: excursionType.Tours__r) {
                names.add(tour.Name);
            }
        }

        return names;
    }

    private void validate(Set<Id> excursionTypeIds, Date startDate, Date endDate) {
        if (excursionTypeIds.isEmpty() || excursionTypeIds == null) {
            throw new TourServiceException('excursionTypeIds can not be null or empty');
        }

        if (startDate == null) {
            throw new TourServiceException('Start Date can not be null');
        }

        if (endDate == null) {
            throw new TourServiceException('End Date can not be null');
        }

        if (startDate.daysBetween(endDate) < 0) {
            throw new TourServiceException('End Date can not be less than Start Date');
        }
    }

    public class TourServiceException extends Exception {}
}