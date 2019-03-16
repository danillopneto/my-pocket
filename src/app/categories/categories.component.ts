import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, ValidationErrors } from '@angular/forms';
import { UtilityService } from '../utility.service';

@Component({
  selector: 'app-categories',
  templateUrl: './categories.component.html',
  styleUrls: ['./categories.component.scss']
})
export class CategoriesComponent implements OnInit {

  categoriesForm: FormGroup;
  submitted: boolean = false;
  success: boolean = false;

  constructor(private formBuilder: FormBuilder, private util: UtilityService) {
    this.categoriesForm = this.formBuilder.group({
      description: ['', Validators.required]
    })
  }

  onSubmit() {
    this.submitted = true;

    if (this.categoriesForm.invalid) {
      this.getDescriptionErrors();
      return;
    }

    this.success = true;
  }

  getFieldErrors(field: string) {
    switch (field) {
      case "description":
        return this.getDescriptionErrors();
      default:
        return "";
    }
  }

  getDescriptionErrors() {
    var result = this.getControlValidationErrors("description");
    var errors = [];
    result.forEach(function (item, index) {
      if (item.error == "required") {
        errors.push("This field is required!");
      }
    })

    return errors.toString();
  }

  getControlValidationErrors(control: string) {
    const result = [];
    const controlErrors: ValidationErrors = this.categoriesForm.get(control).errors;
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

  getFormValidationErrors() {
    const result = [];
    Object.keys(this.categoriesForm.controls).forEach(key => {

      const controlErrors: ValidationErrors = this.categoriesForm.get(key).errors;
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

  ngOnInit() {
  }

  ngAfterViewInit() {
    this.util.prepareComponents();
  }
}
