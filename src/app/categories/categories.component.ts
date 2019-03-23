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
    return $event.srcElement.parentElement.parentElement.parentElement;
  }

  getDataFromEvent($event, selector) {
    var id = this.getParentElementFromEvent($event).querySelectorAll('[name$="' + selector + '"]')[0];
    return id.value;
  }

  editCategory(id) {
    this.categoriesService.getCategory(id).subscribe(data => {
      this.categoriesForm.patchValue({
        category: data
      });
      this.util.hideLoading();
    }, err => {
      this.util.hideLoading();
    });  
  }

  getCategories() {
    this.util.showLoading();

    this.categoriesService.getCategories().subscribe(data => {
        this.categories = data.map(e => {
          return {
              id: e.payload.doc.id,
              color: e.payload.doc.get('color'),
              description: e.payload.doc.get('description'),
          }
        });
        this.util.hideLoading();
      }, err => {
        this.util.hideLoading();
      });
  }

  removeCategory(id) {
    this.util.showLoading();

    this.categoriesService
      .removeCategory(id)
      .catch(() => {        
      })
      .then(() => {
        this.getCategories();
      })
      .finally(() => {
        this.util.hideLoading();
      });
  }

  saveCategory() {
    this.util.showLoading();
    
    var newCategory = new Category(this.categoriesForm.value.category.id, this.color, this.categoriesForm.value.category.description);
    this.categoriesService
      .saveCategory(newCategory)
      .catch(() => {     
        this.util.hideLoading();   
      })
      .then(() => {
        this.categoriesForm = this.createFormGroup();
        this.getCategories();
      })
      .finally(() => {
        this.util.hideLoading();
      });;
  }
}
