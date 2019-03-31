import { Category } from './../models/category.model';
import { CategoriesService } from '../services/categories.service';
import { Component, OnInit } from '@angular/core';
import { FormBuilder, FormGroup, Validators, FormControl } from '@angular/forms';
import { UtilityService } from '../services/utility.service';

@Component({
  selector: 'app-categories',
  templateUrl: './categories.component.html',
  styleUrls: ['./categories.component.scss']
})
export class CategoriesComponent implements OnInit {

  form: FormGroup;
  submitted: boolean = false;
  success: boolean = false;
  categories: Category[];
  color: string = '#ffffff';

  constructor(
    private formBuilder: FormBuilder,
    private util: UtilityService,
    private categoriesService: CategoriesService) {
    this.form = this.createFormGroup();
  }

  createFormGroup() {
    return this.formBuilder.group({
      color: ['#ffffff', null],
      description: new FormControl(),
      id: new FormControl()
    });
  }

  ngOnInit() {
  }

  ngAfterViewInit() {
    this.getCategories();
  }

  onSubmit() {
    this.submitted = true;

    if (this.form.invalid) {
      return;
    }

    this.saveCategory();
    this.success = true;
  }

  onChangeColorCmyk($value) {
    this.color = $value;
  }

  editCategory(id) {
    this.categoriesService.get(id).subscribe(data => {
      this.form.patchValue(data || {});
      this.color = (data|| { color: '#ffffff'}).color;
      this.util.hideLoading();
    }, err => {
      this.util.hideLoading();
    });
  }

  getCategories() {
    this.util.showLoading();

    this.categoriesService.getAllFromUser().subscribe(data => {
      this.categories = data;
      this.util.hideLoading();
    }, err => {
      this.util.hideLoading();
    });
  }

  removeCategory(id) {
    this.util.showLoading();

    this.categoriesService
      .remove(id)
      .catch(() => {
      })
      .then(() => {
      })
      .finally(() => {
        this.util.hideLoading();
      });
  }

  saveCategory() {
    this.util.showLoading();

    var newCategory = new Category(this.form.value.id, this.color, this.form.value.description);
    this.categoriesService
      .save(newCategory)
      .catch(() => {
        this.util.hideLoading();
      })
      .then(() => {
        this.form = this.createFormGroup();
      })
      .finally(() => {
        this.util.hideLoading();
      });;
  }
}
