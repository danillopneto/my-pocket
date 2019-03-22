import { Injectable, EventEmitter } from '@angular/core';
import { FormGroup, ValidationErrors } from '@angular/forms';

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

  prepareComponents() {
    
  }

  showLoading() {
    setTimeout(() => this.loading.emit(true));    
  }

  hideLoading() {
    setTimeout(() => this.loading.emit(false));
  }
}
