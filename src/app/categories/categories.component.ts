import { CategoriesService } from './../categories.service';
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
  categories: Category[];
  color: string = '#ffffff';

  constructor(
    private formBuilder: FormBuilder,
    private util: UtilityService,
    private categoriesService: CategoriesService) {
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
    this.getCategories();
  }

  onSubmit() {
    this.submitted = true;

    if (this.categoriesForm.invalid) {
      return;
    }

    this.saveCategory();
    this.util.prepareComponents();

    this.success = true;
  }

  onChangeColorCmyk($value) {
    this.color = $value;
  }

  getParentElementFromEvent($event) {
    return $event.srcElement.parentElement.parentElement;
  }

  getDataFromEvent($event, selector) {
    var id = this.getParentElementFromEvent($event).querySelectorAll('[name$="' + selector + '"]')[0];
    return id.value;
  }

  editCategory($event) {
    this.categoriesForm.patchValue({
      category: {
        id: this.getDataFromEvent($event, 'id'),
        color: this.getDataFromEvent($event, 'color'),
        description: this.getDataFromEvent($event, 'description')
      }
    });
  }

  getCategories() {
    this.util.showLoading();

    this.categoriesService.getCategories()
      .subscribe((data: Category[]) => {
        this.categories = data;
        this.util.hideLoading();
      }, err => {
        this.util.hideLoading();
      });
  }

  removeCategory($event) {
    this.util.showLoading();

    this.categoriesService
      .removeCategory(this.getDataFromEvent($event, 'id'))
      .subscribe(() => {
        this.getCategories();
        this.util.hideLoading();
      }, err => {
        this.util.hideLoading();
      });
  }

  saveCategory() {
    this.util.showLoading();
    
    var newCategory = new Category(this.categoriesForm.value.category.id, this.color, this.categoriesForm.value.category.description);
    this.categoriesService
      .saveCategory(newCategory)
      .subscribe(() => {
        this.getCategories();
        this.util.hideLoading();
        this.categoriesForm = this.createFormGroup();
      }, err => {
        this.util.hideLoading();
      });
  }
}
