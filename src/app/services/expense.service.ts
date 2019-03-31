import { UtilityService } from './utility.service';
import { Injectable } from '@angular/core';
import { BaseAngularService } from './base-angular.service';
import { Expense } from '../models/expense.model';
import { QueryFn, AngularFirestore } from '@angular/fire/firestore';

@Injectable({
  providedIn: 'root'
})
export class ExpensesService extends BaseAngularService<Expense> {
  public relativeUrl: string;

  constructor(
              protected firestore: AngularFirestore,
              protected util: UtilityService) {
    super(firestore, util);
  }

  getCollectionReference(queryFn?: QueryFn) {
    return this.firestore.collection('danillopneto').doc("userData").collection<Expense>('expenses', queryFn);
  }

  getYearReference(date: string) {
    return this.getCollectionReference(ref => ref.where('year', '==', this.util.getYearFromDate(date)));
  }
  
  getMonthReference(date: string) {
    return this.getCollectionReference(ref => 
        ref.where('year', '==', this.util.getYearFromDate(date))
           .where('month', '==', this.util.getMonthFromDate(date)));
  }

  getDayReference(date: string) {
    return this.getCollectionReference(ref => 
        ref.where('year', '==', this.util.getYearFromDate(date))
          .where('month', '==', this.util.getMonthFromDate(date))
          .where('day', '==', this.util.getDayFromDate(date)));
  }

  getExpensesOnDay(date: string) {
    return this.getDayReference(date).snapshotChanges();
  }
}
