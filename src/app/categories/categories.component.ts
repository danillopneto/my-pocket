import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, FormControl } from '@angular/forms';
import { UtilityService } from '../utility.service';
import { Category } from './../models/category.model';

@Component({
  selector: 'app-categories',
  templateUrl: './categories.component.html',
  styleUrls: ['./categories.component.scss']
})
export class CategoriesComponent implements OnInit {

  categoriesForm: FormGroup;
  submitted: boolean = false;
  success: boolean = false;
  categories: Category[] = [];
  color: string = '#ffffff';

  constructor(private formBuilder: FormBuilder, private util: UtilityService) {
    this.categoriesForm = this.createFormGroup();
  }

  createFormGroup() {
    return this.formBuilder.group({
      category: this.formBuilder.group({
        color: ['#ffffff', null],
        description: new FormControl(),
        id: new FormControl()
      })
    });
  }

  ngOnInit() {
  }

  ngAfterViewInit() {
    this.util.prepareComponents();
  }

  onSubmit() {
    this.submitted = true;

    if (this.categoriesForm.invalid) {
      return;
    }

    var data = this.categoriesForm.value;
    this.categories.push(new Category("", this.color, data.category.description));
    this.categoriesForm = this.createFormGroup();
    this.util.prepareComponents();

    this.success = true;
  }

  onChangeColorCmyk($value) {
    this.color = $value;
  }
}
