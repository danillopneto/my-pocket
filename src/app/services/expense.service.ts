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
    return this.firestore.collection<Expense>('expenses', queryFn);
  }

  getYearReference(date: number) {
    var year = this.util.getYearFromDate(date);
    return this.getCollectionReference(ref => ref
          .where('date', '>=', parseInt(year.concat('0000'), 10))
          .where('date', '<=', parseInt(year.concat('1231'), 10)));
  }
  
  getMonthReference(date: number) {
    var year = this.util.getYearFromDate(date);
    var month = this.util.getMonthFromDate(date);
    return this.getCollectionReference(ref => 
        ref.where('date', '>=', parseInt(year.concat(month, '00'), 10))
           .where('date', '<=', parseInt(year.concat(month, '31'), 10)));
  }

  getDayReference(date: number) {
    return this.getCollectionReference(ref => 
        ref.where('date', '==', date));
  }

  getExpensesOnDay(date: number) {
    return this.getDayReference(date).valueChanges();
  }

  getUserYearReference(date: number) {
    var year = this.util.getYearFromDate(date);
    return this.getCollectionReference(ref => ref
          .where('userId', '==', this.util.userId)
          .where('date', '>=', parseInt(year.concat('0000'), 10))
          .where('date', '<=', parseInt(year.concat('1231'), 10)));
  }
  
  getUserMonthReference(date: number) {
    var year = this.util.getYearFromDate(date);
    var month = this.util.getMonthFromDate(date);
    return this.getCollectionReference(ref => 
        ref.where('userId', '==', this.util.userId)
           .where('date', '>=', parseInt(year.concat(month, '01'), 10))
           .where('date', '<=', parseInt(year.concat(month, '31'))));
  }

  getUserDayReference(date: number) {
    return this.getCollectionReference(ref => 
        ref.where('userId', '==', this.util.userId)
           .where('date', '==', date));
  }

  getUserExpensesOnDay(date: number) {
    return this.getUserDayReference(date).valueChanges();
  }
}
