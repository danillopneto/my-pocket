import { Injectable, EventEmitter } from '@angular/core';
import { FormGroup, ValidationErrors } from '@angular/forms';
import { Expense } from '../models/expense.model';

@Injectable({
  providedIn: 'root'
})
export class UtilityService {
  
  loading: EventEmitter<boolean> = new EventEmitter();;

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

  getDayFromDate(date: string) {
    return date.replace('-', '').substr(7, 2);
  }

  getMonthFromDate(date: string) {
    return date.replace('-', '').substr(4, 2);
  }

  getYearFromDate(date: string) {
    return date.substr(0, 4);
  }

  getFullDate(expense: Expense): string {
    return expense.month.concat('/', expense.day, '/', expense.year);
  }
}
