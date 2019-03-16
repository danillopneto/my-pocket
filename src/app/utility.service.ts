import { Injectable } from '@angular/core';
import { FormGroup, ValidationErrors } from '@angular/forms';
import M from "materialize-css/dist/js/materialize.min.js";

@Injectable({
  providedIn: 'root'
})
export class UtilityService {

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
    M.CharacterCounter.init(document.querySelectorAll('.character-counter'));
    M.Carousel.init(document.querySelectorAll('.carousel'));
  }
}
