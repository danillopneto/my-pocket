import { Injectable, EventEmitter } from '@angular/core';
import { FormGroup, ValidationErrors } from '@angular/forms';
import { Expense } from '../models/expense.model';

@Injectable({
  providedIn: 'root'
})
export class UtilityService {
  userId: string;

  loading: EventEmitter<boolean> = new EventEmitter();

  constructor() { }

  getControlValidationErrors(formGroup: FormGroup, control: string) {
    const result = [];
    const controlErrors: ValidationErrors = formGroup.get(control).errors;
    if (controlErrors) {
      Object.keys(controlErrors).forEach(keyError => {
        result.push({
          'error': keyError,
          'value': controlErrors[keyError]
        });
      });
    }

    return result;
  }

  getFormValidationErrors(form: FormGroup) {
    const result = [];
    Object.keys(form.controls).forEach(key => {

      const controlErrors: ValidationErrors = form.get(key).errors;
      if (controlErrors) {
        Object.keys(controlErrors).forEach(keyError => {
          result.push({
            'control ': key,
            'error': keyError,
            'value': controlErrors[keyError]
          });
        });
      }
    });

    return result;
  }

  showLoading() {
    setTimeout(() => this.loading.emit(true));    
  }

  hideLoading() {
    setTimeout(() => this.loading.emit(false));
  }

  getDayFromDate(date: number) {
    return date.toString().substr(6, 2);
  }

  getMonthFromDate(date: number) {
    return date.toString().substr(4, 2);
  }

  getYearFromDate(date: number) {
    return date.toString().substr(0, 4);
  }

  getFormattedDate(date: number) {
    return this.getDayFromDate(date).concat('/', this.getMonthFromDate(date), '/', this.getYearFromDate(date));
  }

  getFullDate(date: string) {
    return parseInt(date.replace(/-/g, '').split('T')[0], 10);
  }

  getDateFormat(date: number) {
    var day = parseInt(this.getDayFromDate(date), 10);
    var month = parseInt(this.getMonthFromDate(date), 10);
    var year = parseInt(this.getYearFromDate(date), 10);
    return new Date(year, month - 1, day);
  }

  setUserId(userId: string) {
    this.userId = userId;
  }
}
